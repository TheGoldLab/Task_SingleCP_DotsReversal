"""
This module is designed to generate trials for our task with the
correct statistics


Example usage:
  >>>> trials = Trials(0.8, 204, marginal_tolerance=0.02)
  >>>> trials.attempt_number
  >>>> trials.save_to_csv('SOME/PATH/TO/FILE.csv')
"""
import numpy as np
import pandas as pd

ALLOWED_PROB_CP = {0.2, 0.5, 0.8}  # overall probability of a change-point trial
CP_TIME = 200  # in msec
MARGINALS_TEMPLATE = {
    'coh': {0: 0, 'th': 0, 100: 0},
    'vd': {100: 0, 200: 0, 300: 0, 400: 0},
    'dir': {'left': 0, 'right': 0},
    'cp': {True: 0, False: 0}
}


def validate_marginal_keys(marg_type, marg_dict):
    """
    asserts validity of keys of marg_dict
    :param marg_type: (str) one of the keys from marginals_template defined inside function
    :param marg_dict: (dict) dict representing the marginals for a single independent variable
    :return: None
    """
    assert set(MARGINALS_TEMPLATE[marg_type].keys()) == set(marg_dict.keys())


def validate_marginal_values(marg_dict, precision=1 / 10000000):
    """
    checks the marginals sum to 1, up to some precision
    :param marg_dict: (dict) dict representing the marginals for a single independent variable
    :param precision: positive number under which any number is assimilated with 0
    :return: None
    """
    assert abs(sum(marg_dict.values()) - 1) < precision


def validate_marginal(marg_type, marg_dict):
    """
    convenience function which validates keys and values of a marginals dict with default kwargs
    :param marg_type: (str) one of the keys from marginals_template defined inside function
    :param marg_dict: (dict) dict representing the marginals for a single independent variable
    :return:
    """
    validate_marginal_keys(marg_type, marg_dict)
    validate_marginal_values(marg_dict)


def get_marginals(df):
    """
    computes marginal distributions of all independent variables
    :param df: dataframe of trials as returned by self.get_n_trials()
    :return: dict with same format than MARGINALS_TEMPLATE, but empirical probs as values
    """
    emp_marginals = {
        'coh': {0: 0, 'th': 0, 100: 0},
        'vd': {100: 0, 200: 0, 300: 0, 400: 0},
        'dir': {'left': 0, 'right': 0},
        'cp': {True: 0, False: 0}}

    assert set(emp_marginals.keys()) == set(MARGINALS_TEMPLATE.keys())

    tot_trials = len(df)

    for indep_var in emp_marginals.keys():
        for key in emp_marginals[indep_var].keys():
            emp_marginals[indep_var][key] = len(df[df[indep_var] == key]) / tot_trials

        validate_marginal(indep_var, emp_marginals[indep_var])

    return emp_marginals


class Trials:
    """
    class to create data frames of trials
    """
    def __init__(self, prob_cp, num_trials,
                 seed=1,
                 coh_marginals={0: .4, 'th': .5, 100: .1},
                 vd_marginals={100: .1, 200: .1, 300: .4, 400: .4},
                 dir_marginals={'left': 0.5, 'right': 0.5},
                 max_attempts=10000,
                 marginal_tolerance=0.05):

        assert 0 < marginal_tolerance < 1
        self.marginal_tolerance = marginal_tolerance

        # for reproducibility
        np.random.seed(seed)

        # validate core marginals
        validate_marginal('coh', coh_marginals)
        validate_marginal('vd', vd_marginals)
        validate_marginal('dir', dir_marginals)

        # validate prob_cp and its corresponding marginal
        assert prob_cp in ALLOWED_PROB_CP
        self.prob_cp = prob_cp
        cp_marginals = {False: 1 - self.prob_cp, True: self.prob_cp}
        validate_marginal('cp', cp_marginals)

        # compute cond_prob_cp (i.e. the probability of a CP, given that it is a long trial)
        prob_long_trial = 0
        for k, v in vd_marginals.items():
            if k > CP_TIME:
                prob_long_trial += v

        cond_prob_cp = self.prob_cp / prob_long_trial

        assert 0 <= cond_prob_cp <= 1
        self.cond_prob_cp = cond_prob_cp  # probability of a CP, given that it is a long trial

        self.theoretical_marginals = {
            'coh': coh_marginals,
            'vd': vd_marginals,
            'dir': dir_marginals,
            'cp': cp_marginals
        }
        assert set(self.theoretical_marginals.keys()) == set(MARGINALS_TEMPLATE.keys())

        """
        the following attribute will be set to an actual data frame if generation succeeds with self.check_conditions()
        """
        self.empirical_marginals = None

        # build all combinations of independent variables, each comb will correspond to a trial
        self.combinations = {}  # dict where the values are the joint probabilities
        for dir_k, dir_val in self.theoretical_marginals['dir'].items():
            for coh_k, coh_val in self.theoretical_marginals['coh'].items():
                for vd_k, vd_val in self.theoretical_marginals['vd'].items():
                    self.combinations[(coh_k, vd_k, dir_k)] = coh_val * vd_val * dir_val

        attempt = 0
        assert attempt < max_attempts

        try_again = True
        while attempt < max_attempts and try_again:
            trial_df = self.get_n_trials(num_trials)
            attempt += 1

            # try again unless conditions are met
            try_again = not self.check_conditions(trial_df)

        if try_again:
            print(f'after {attempt} attempts, no trial set met the conditions\n'
                  f'trial generation failed. You may try again with another seed,\n'
                  f'or increase the max_attempts argument')
            self.trial_data = None  # generation failed
        else:
            self.trial_data = trial_df

        self.attempt_number = attempt

    def get_n_trials(self, n):
        rows = []  # will be a list of dicts, where each dict is a pandas.DataFrame row
        for trial in range(n):
            comb_keys = list(self.combinations.keys())
            comb_number = np.random.choice(len(comb_keys), p=list(self.combinations.values()))
            comb = comb_keys[comb_number]

            # this is a CP trial only if VD > 200 and biased coin flip turns out HEADS
            is_cp = comb[1] > CP_TIME and np.random.random() < self.cond_prob_cp

            rows.append({'coh': comb[0], 'vd': comb[1], 'dir': comb[2], 'cp': is_cp})

        trials_dataframe = pd.DataFrame(rows)
        return trials_dataframe

    def check_conditions(self, df, append_marginals=True):
        """
        we want at least five trials per Coh-VD pairs
        we don't want the empirical marginals to deviate from the theoretical ones by more than 5%
        """
        num_cohvd_pairs = np.sum(df.duplicated(subset=['coh', 'vd'], keep=False))
        if num_cohvd_pairs < 5:
            return False

        emp_marginals = get_marginals(df)

        for indep_var in emp_marginals.keys():
            for key in emp_marginals[indep_var].keys():
                error = abs(emp_marginals[indep_var][key] - self.theoretical_marginals[indep_var][key])
                if error > self.marginal_tolerance:
                    return False

        if append_marginals:
            self.empirical_marginals = emp_marginals

        return True

    def save_to_csv(self, filename='trials.csv'):
        if self.trial_data is None:
            print('No data to write')
        else:
            self.trial_data.to_csv(filename, index=False)


if __name__ == '__main__':
    pass

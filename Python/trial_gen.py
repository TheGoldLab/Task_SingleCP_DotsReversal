"""
This module is designed to generate trials for our task with the
correct statistics

Example usage:
  >>>> trials = Trials(prob_cp=0.8, num_trials=204, marginal_tolerance=0.02)
  >>>> trials.attempt_number
  >>>> trials.save_to_csv('/foo/bar.csv')  # a .json file gets created for meta data
  >>>> reloaded_trials = Trials(from_file='/foo/bar.csv')  # also loads meta data from .json file
"""
import numpy as np
import pandas as pd
import json
import hashlib

ALLOWED_PROB_CP = {0.3, 0.7}  # overall probability of a change-point trial
CP_TIME = 200  # in msec
MARGINALS_TEMPLATE = {
    'coh': {0: 0, 'th': 0, 100: 0},
    'vd': {100: 0, 200: 0, 250: 0, 300: 0, 400: 0, 600: 0},
    'dir': {'left': 0, 'right': 0},  # this is the FINAL direction of motion
    'cp': {True: 0, False: 0}
}


def check_extension(f, extension):
    """
    check that filename has the given extension
    :param f: (str) filename
    :param extension: (str) extension with or without the dot. So 'csv', '.csv', 'json', '.json' are all valid
    :return: asserts that string ends with proper extension
    """
    if extension[0] == '.':
        full_extension = extension
    else:
        full_extension = '.' + extension

    assert f[-len(extension):] == extension, f'data filename {f} does not have a {full_extension} extension'


def standard_meta_filename(filename):
    """
    utility to quickly define the filename for the metadata, given the filename for the data
    :param filename: (str) path to data file
    :return: (str) path to metadata file
    """
    check_extension(filename, 'csv')
    return filename[:-4] + '_metadata.json'


def md5(fname):
    """
    function taken from here
    https://stackoverflow.com/a/3431838
    :param fname: filename
    :return: string of hexadecimal number
    """
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()


def validate_marginal_keys(marg_type, marg_dict):
    """
    asserts validity of keys of marg_dict
    :param marg_type: (str) one of the keys from marginals_template defined inside function
    :param marg_dict: (dict) dict representing the marginals for a single independent variable
    :return: None
    """
    k1 = MARGINALS_TEMPLATE[marg_type].keys()
    k2 = marg_dict.keys()
    assert set(k1) == set(k2), f'k1 {set(k1)}; k2 {set(k2)}'


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

    # todo: generate this dict from MARGINALS_TEMPLATE!
    emp_marginals = {
        'coh': {0: 0, 'th': 0, 100: 0},
        'vd': {100: 0, 200: 0, 250: 0, 300: 0, 400: 0, 600: 0},
        'dir': {'left': 0, 'right': 0},  # this is the FINAL direction of motion
        'cp': {True: 0, False: 0}}

    assert set(emp_marginals.keys()) == set(MARGINALS_TEMPLATE.keys())

    tot_trials = len(df)

    for indep_var in emp_marginals.keys():
        for k in emp_marginals[indep_var].keys():
            emp_marginals[indep_var][k] = len(df[df[indep_var] == k]) / tot_trials

        validate_marginal(indep_var, emp_marginals[indep_var])

    return emp_marginals


def format2snowdots(df):
    """
    :param df: pandas.DataFrame produced by the Trials class
    :return: pandas.DataFrame with column names and row values compatible with snow-dots (Lab_Matlab_Control v1.0.1)
    """
    assert set(df.columns) == {'cp', 'coh', 'dir', 'vd'}
    # snowdots_cols = ('direction', 'coherence', 'reversal', 'duration', 'finalDuration')

    # ref: https://stackoverflow.com/a/26887820
    def convert_direction(row):  # initial direction depends on final direction and CP presence
        dirmap = {'left': 180, 'right': 0}  # maps direction to angle
        revdirmap = {'left': 0, 'right': 180}  # reversed mapping on purpose
        return revdirmap[row['dir']] if row['cp'] else dirmap[row['dir']]
    direction_series = df.apply(lambda row: convert_direction(row), axis=1)

    def convert_coherence(row):
        return -1 if row['coh'] == 'th' else row['coh']
    coherence_series = df.apply(lambda row: convert_coherence(row), axis=1)

    def convert_reversal(row):
        return 0.2 if row['cp'] else 0
    reversal_series = df.apply(lambda row: convert_reversal(row), axis=1)

    snowdots_df = pd.DataFrame({
        'direction': direction_series,
        'coherence': coherence_series,
        'reversal': reversal_series,
        'duration': df['vd'] / 1000,
        'finalDuration': pd.Series(['NaN']*len(direction_series))
    })

    return snowdots_df


class Trials:
    """
    class to create data frames of trials

    Note, this class may be instantiated in two ways, controlled by the from_file kwarg to the __init__ method.
    These ways result in a slightly distinct attribute list for this class. What should always be true, is that any
    attribute appearing when the object is 'loaded from file' should also exist when the object is 'generated'.
    We list below the attributes in these two cases, as of 03 June 2019
    generated:
        attempt_number
        combinations
        cond_prob_cp
        csv_filename
        csv_md5
        empirical_marginals
        loaded_from_file
        marginal_tolerance
        num_trials
        prob_cp
        seed
        theoretical_marginals
        trial_data
    loaded:
        cond_prob_cp
        csv_filename
        csv_md5
        empirical_marginals
        loaded_from_file
        marginal_tolerance
        num_trials
        prob_cp
        seed
        theoretical_marginals
        trial_data
    """
    def __init__(self,
                 prob_cp=0.3,
                 num_trials=820,  # 205 * 4
                 seed=1,
                 coh_marginals=((0, .4), ('th', .55), (100, .05)),
                 vd_marginals=((100, .1), (200, .1), (250, .25), (300, .25), (400, .25), (600, .05)),
                 dir_marginals=(('left', 0.5), ('right', 0.5)),
                 max_attempts=10000,
                 marginal_tolerance=0.02,
                 from_file=None):
        """
        :param prob_cp: theoretical proba of a CP trials over all trials
        :param num_trials: number of trials in the data attached to object
        :param seed: seed used to generate the data
        :param coh_marginals: marginal probabilities for coherence values, across all trials. tuple to construct dict
        :param vd_marginals: marginal prob for viewing duration values, across all trials. tuple as coh_marginals
        :param dir_marginals: marginal probabilities for direction values, across all trials. tuple as coh_marginals
        :param max_attempts: max number of iterations to do to try to generate trials with correct statistics
        :param marginal_tolerance: tolerance in the empirical marginals of the generated trials
        :param from_file: filename to load data from. If None, data is randomly generated. If a filename is provided,
                          it should have a .csv extension and a corresponding metadata file with name equal to standard_
                          meta_filename(filename) should exist. Note that if data and meta_data are loaded from files,
                          all other kwargs provided to __init__ will be overriden by self._load_from_file()
        """
        if from_file is None:
            self.loaded_from_file = False

            assert 0 < marginal_tolerance < 1
            self.marginal_tolerance = marginal_tolerance

            # for reproducibility
            assert isinstance(seed, int)
            self.seed = seed
            np.random.seed(self.seed)

            # validate core marginals
            coh_marginals = dict(coh_marginals)
            vd_marginals = dict(vd_marginals)
            dir_marginals = dict(dir_marginals)

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

                """
                the following line is important because 'coh' column might be interpreted as int if no 'th' value 
                appears, and this produces a TypeError when filtering against the string 'th'
                """
                trial_df.coh = trial_df.coh.astype('category')

                # try again unless conditions are met
                try_again = not self.check_conditions(trial_df)

            if try_again:
                print(f'after {attempt} attempts, no trial set met the conditions\n'
                      f'trial generation failed. You may try again with another seed,\n'
                      f'or increase the max_attempts argument')
                self.trial_data = None  # generation failed
                self.num_trials = 0
            else:
                self.trial_data = trial_df
                self.num_trials = len(trial_df)

            self.attempt_number = attempt
            self.csv_md5 = None
            self.csv_filename = None
        else:
            self._load_from_file(from_file)

    @staticmethod
    def load_meta_data(filename):
        """
        load metadata about trials from file
        :param filename: (str) filename of either the trials data in csv format or its corresponding metadata in json
                         format. If filename with .csv extension is provided, standard_meta_filename() is invoked
        :return: (dict) metadata
        """
        try:
            check_extension(filename, 'csv')
            meta_filename = standard_meta_filename(filename)
        except AssertionError:
            try:
                check_extension(filename, 'json')
                meta_filename = filename
            except AssertionError:
                print(f'file {filename} has neither .csv nor .json extension')
                raise ValueError

        with open(meta_filename, 'r') as fp:
            meta_data = json.load(fp)
        return meta_data

    @staticmethod
    def md5check_from_metadata(csv_filename, meta_filename=None):
        """
        checks whether the data in the csv file corresponds to the MD5 checksum stored in the metadata file
        :param csv_filename: (str)
        :param meta_filename: (str)
        :return: simply asserts equality of checksums
        """
        if meta_filename is None:
            meta_filename = standard_meta_filename(csv_filename)
        assert Trials.load_meta_data(meta_filename)['csv_md5'] == md5(csv_filename), 'MD5 check failed!'
        print('MD5 verified!')

    def _load_from_file(self, fname, meta_file=None):
        """
        load full object from .csv file and its corresponding metadata file
        :param fname: (str) path to csv file
        :param meta_file: (str or None) either path to metadatafile or None (default).
                          If None, standard_meta_filename() is called
        :return: sets many attributes
        """
        if meta_file is None:
            meta_file = standard_meta_filename(fname)
        Trials.md5check_from_metadata(fname, meta_filename=meta_file)
        meta_data = Trials.load_meta_data(meta_file)

        # load data into pandas.DataFrame and attach it as attribute
        self.trial_data = pd.read_csv(fname)

        # set key-value pairs from metadata as attributes
        for k, v in meta_data.items():
            setattr(self, k, v)

        self.loaded_from_file = True

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
        # count Coh-VD pairs
        num_cohvd_pairs = np.sum(df.duplicated(subset=['coh', 'vd'], keep=False))
        if num_cohvd_pairs < 5:
            return False

        # check deviation between empirical marginals and theoretical ones
        emp_marginals = get_marginals(df)

        for indep_var in emp_marginals.keys():
            for key in emp_marginals[indep_var].keys():
                error = abs(emp_marginals[indep_var][key] - self.theoretical_marginals[indep_var][key])
                if error > self.marginal_tolerance:
                    return False

        if append_marginals:
            self.empirical_marginals = emp_marginals

        return True

    def save_to_csv(self, filename, with_meta_data=True, snowdots_fmt=True):
        if self.trial_data is None:
            print('No data to write')
        else:
            check_extension(filename, 'csv')

            if snowdots_fmt:
                formatted_data = format2snowdots(self.trial_data)
                formatted_data.to_csv(filename, index=False)
            else:
                self.trial_data.to_csv(filename, index=False)
            print(f"file {filename} created")

            if with_meta_data:
                meta_filename = standard_meta_filename(filename)
                meta_dict = {
                    'seed': self.seed,
                    'num_trials': self.num_trials,
                    'prob_cp': self.prob_cp,
                    'cond_prob_cp': self.cond_prob_cp,
                    'theoretical_marginals': self.theoretical_marginals,
                    'empirical_marginals': self.empirical_marginals,
                    'marginal_tolerance': self.marginal_tolerance,
                    'csv_filename': filename,
                    'csv_md5': md5(filename)
                }
                with open(meta_filename, 'w') as fp:
                    json.dump(meta_dict, fp, indent=4)
            print(f"medatadata file {meta_filename} created")

    def count_conditions(self, ind_vars):
        # todo: to count number of trials for a given combination of independent variables values
        pass


if __name__ == '__main__':
    """
    todo: creates N blocks of trials per prob_cp value, gives standardized names to files  
    """
    # marg_tol = 0.01  # max deviation allowed between theoretical and empirical marginal probabilities
    all_vals = list(ALLOWED_PROB_CP - {0})

    # number of blocks in total for the dual-report task
    num_dual_report_blocks = 2

    # number of blocks to enforce for each prob_cp value (other than 0)
    # ensure the latter divides the former
    assert np.mod(num_dual_report_blocks, len(all_vals)) == 0
    num_blocks_single_prob_cp = num_dual_report_blocks / len(all_vals)

    def gen_rand_prob_cp_seq(cp_vals, tot_num_blocks):
        """
        Generates a random sequence of prob_cp values to assign to each block.
        In effect, samples a path from a len(cp_vals)-state Discrete Time Markov Chain
        where the prob of transitioning from one state to itself is 0 for all states,
        and the probability of transitioning from one state to any other state is uniform.
        :param cp_vals: list of possible prob_cp values
        :param tot_num_blocks: total number of blocks
        :return: list of prob_cp values
        """
        # build random ordering of prob_cp across blocks
        last_idx = np.random.randint(2)  # draws a number at random in the set {0, 1}

        num_vals = len(cp_vals)
        val_idxs = {i for i in range(num_vals)}

        prob_list = [cp_vals[last_idx]]

        for r in range(tot_num_blocks - 1):
            new_idxs = list(val_idxs - {last_idx})    # update allowed indices for this block (enforce a transition)
            last_idx = new_idxs[np.random.randint(num_vals - 1)]  # pick one of the other two indices at random
            prob_list.append(all_vals[last_idx])

        return prob_list

    def validate_prob_cp_seq(seq, num_blocks, num_blocks_seq, cp_vals):
        assert len(seq) == num_blocks
        for prob_cp in cp_vals:
            cc = 0  # counter
            for s in seq:
                if s == prob_cp:
                    cc += 1
            if cc != num_blocks_seq:
                return False
        return True

    prob_cp_list = [0 for _ in range(num_dual_report_blocks)]
    maxout = 1000  # total number of iterations allowed for the following while loop
    counter = 0
    while not validate_prob_cp_seq(prob_cp_list, num_dual_report_blocks, num_blocks_single_prob_cp, all_vals):
        prob_cp_list = gen_rand_prob_cp_seq(all_vals, num_dual_report_blocks)
        counter += 1
        # print('all_vals', all_vals)
        # print('num_dual_report_blocks', num_dual_report_blocks)
        # print('prob_cp_list', prob_cp_list)
        # print('counter in while loop', counter)
        if counter == maxout:
            print(f"after {counter} attempts, not proper prob_cp list was reached")
            break
    else:
        print(f'prob cp list for dual-report blocks found after {counter} attempts')
        print(prob_cp_list)

        dual_report_start_index = 0
        # block_length = 250  # number of trials to use for each block

        filenames = []  # ['Tut1.csv', 'Tut2.csv', 'Block2.csv', 'Tut3.csv']
        for idx in range(num_dual_report_blocks):
            filenames.append('Block' + str(idx + dual_report_start_index) + '.csv')

        count = 0
        dual_report_block_count = 0

        for file in filenames:
            count += 1

            t = Trials(prob_cp=prob_cp_list[dual_report_block_count], seed=count)
            t.save_to_csv(file)
            dual_report_block_count += 1

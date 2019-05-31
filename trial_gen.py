"""
This module is designed to generate trials for our task with the
correct statistics
"""
import numpy as np
import pandas as pd
import pprint

# for reproducibility
np.random.seed(1)

marginals = {
    'coh': {0: .4, 'th': .5, 100: .1},
    'vd': {100: .1, 200: .1, 300: .4, 400: .4},
    'dir': {'left': 0.5, 'right': 0.5}}

# check all marginals sum to 1 
for m in marginals.values():
    assert sum(m.values()) == 1

# build all combinations
combinations = {}  # dict where the values are the joint probabilities
for dir_k, dir_val in marginals['dir'].items():
    for coh_k, coh_val in marginals['coh'].items():
        for vd_k, vd_val in marginals['vd'].items():
            combinations[(coh_k, vd_k, dir_k)] = coh_val * vd_val * dir_val


def get_n_trials(n, prob_cp):
    rows = []  # will be a list of dicts, where each dict is a pandas.DataFrame row
    for trial in range(n):
        # print(type(combinations.keys()))
        # print(len(combinations.keys()))
        # print(list(combinations.keys()))
        # print(list(combinations.values()))
        comb_keys = list(combinations.keys())
        comb_number = np.random.choice(len(comb_keys), p=list(combinations.values()))
        comb = comb_keys[comb_number]
        # this is a CP trial only if VD > 200 and biased coin flip turns out HEADS
        cp = comb[1] > 200 and np.random.random() < prob_cp

        rows.append({'coh': comb[0], 'vd': comb[1], 'dir': comb[2], 'cp': cp})

    trials = pd.DataFrame(rows)
    return trials


def check_conditions(df):
    """
    we want at least five trials per Coh-VD pairs
    we don't want the empirical marginals to deviate from the theoretical ones by more than 5%
    """
    num_cohvd_pairs = np.sum(df.duplicated(subset=['coh', 'vd'], keep=False))
    if num_cohvd_pairs < 5:
        return False

    emp_marginals = get_marginals(df)
    tolerance = .05
    # todo: write tolerance check!


def get_marginals(df):
    """
    computes marginal distributions of all independent variables
    :param df:
    :return: dict with same format than marginals, but empirical probs as values
    """
    emp_marginals = {
        'coh': {0: 0, 'th': 0, 100: 0},
        'vd': {100: 0, 200: 0, 300: 0, 400: 0},
        'dir': {'left': 0, 'right': 0},
        'cp': {True: 0, False: 0}}

    tot_trials = len(df)

    for indep_var in emp_marginals.keys():
        for key in emp_marginals[indep_var].keys():
            emp_marginals[indep_var][key] = len(df[df[indep_var] == key]) / tot_trials

    # check all marginals sum to 1, up to some precision
    precision = 1 / 10000000
    for k, v in emp_marginals.items():
        assert abs(sum(v.values()) - 1) < precision
    return emp_marginals


if __name__ == '__main__':
    pcp = 1  # probability of a change-point
    num_trials = 200
    trials = get_n_trials(num_trials, pcp)
    check_conditions(trials)
    print(f'data frame of {len(trials)} trials created with probCP = {pcp} (10 first rows below)')
    print(trials.iloc[:10, ])
    print('\nmarginals')
    pprint.pprint(get_marginals(trials))

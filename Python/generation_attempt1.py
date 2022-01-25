from trial_gen import *


if __name__ == "__main__":
    trials = Trials(
        prob_cp=0.3,
        num_trials=205,
        seed=1,
        coh_marginals={0: .4, 'th': .55, 100: .05},
        vd_marginals={100: .125, 200: .125, 250: .25, 300: .25, 400: .25},
        dir_marginals={'left': 0.5, 'right': 0.5},
        max_attempts=10000,
        marginal_tolerance=0.05)
    print(trials.attempt_number)
    trials.save_to_csv('trials_low.csv')

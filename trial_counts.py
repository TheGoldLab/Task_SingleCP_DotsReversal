from trial_gen import *


if __name__ == '__main__':
    """
    Aim is to display a data frame with the following columns:
    prob_cp, coh, cp, vd, N
    
    Strategy is as follows:
    1/ loop over prob_cp values
    2/ gather all data corresponding to this prob_cp value into single data frame
    3/ append prob_cp column
    4/ compute number of unique combinations in such data frame
    5/ go to next iteration of 1/, while appending data frames
    """
    filenames = ['Blocks003/Block' + str(i) + '.csv' for i in range(2,12)]
    meta_fnames = ['Blocks003/Block' + str(i) + '_metadata.json' for i in range(2, 12)]

    list_of_df = []
    for pcp in ALLOWED_PROB_CP:  # step 1
        block_dfs = []
        files_to_visit = []
        for f in filenames:
            mdat = Trials.load_meta_data(f)
            if mdat['prob_cp'] == pcp:
                files_to_visit.append(f)
                block_dfs.append(Trials(from_file=f).trial_data.iloc[:200])
        df = pd.concat(block_dfs)  # step 2
        # step 4 (makes more sense to do it here)
        new_df = df.groupby(['coh', 'cp', 'vd']).size().reset_index(name='count')
        new_df['prob_cp'] = pcp  # step 3
        list_of_df.append(new_df)

    to_write = pd.concat(list_of_df)
    to_write.to_csv('Blocks003/trial_comb_count.csv', index=False)

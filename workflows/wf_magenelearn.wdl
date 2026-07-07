version 1.0

import "../tasks/task_magenelearn.wdl" as run_magenelearn

workflow magenelearn_wf {
  input{
    String run_name
    String magenelearn_mode
  }
  call run_magenelearn.magenelearn {
    input:
      name = run_name,
      mode = magenelearn_mode
  }
  output {
    String magenelearn_version = magenelearn.version
    File?  split_log = magenelearn.split_log
    File? train_tsv = magenelearn.train_tsv
    File? test_tsv = magenelearn.test_tsv
    File? chisq_top_features = magenelearn.chisq_top_features
    File? chisq_log = magenelearn.chisq_log
    File? muvr_log = magenelearn.muvr_log
    File? muvr_min = magenelearn.muvr_min
    File? muvr_max = magenelearn.muvr_max
    File? muvr_mid = magenelearn.muvr_mid
    File? boruta_log = magenelearn.boruta_log
    File? boruta_min = magenelearn.boruta_min
    File? boruta_max = magenelearn.boruta_max
    File? boruta_mid = magenelearn.boruta_mid
    File? final_features_log = magenelearn.final_features_log
    File? final_features_test = magenelearn.final_features_test
    File? final_features_train = magenelearn.final_features_train
    File? train_log = magenelearn.train_log
    File? train_model_file = magenelearn.train_model_file
  }
}
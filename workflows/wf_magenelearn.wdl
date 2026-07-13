version 1.0

import "../tasks/task_magenelearn_train.wdl" as run_magenelearn_train
import "../tasks/task_magenelearn_test.wdl" as run_magenelearn_test

workflow magenelearn_wf {
  input{
    String run_name
    File? external_features
    String? label
    String? group_column
    String mode = "full"
  }
  Boolean run_train = mode == "full" || mode == "train"
  Boolean run_test  = mode == "full" || mode == "test"
  if (run_train){
    call run_magenelearn_train.magenelearn_train {
      input:
        name = run_name,
        features = external_features,
        label = label,
        group_column = group_column
    }
  }
  if (run_test){
    call run_magenelearn_test.magenelearn_test {
      input:
        name = run_name,
        model_file = magenelearn_train.train_model_file,
        features_file = select_first([magenelearn_train.muvr_min, magenelearn_train.boruta_min]),
        features_test = magenelearn_train.final_features_test,
        label = label,
        group_column = group_column
    }
  }
  output {
    String? magenelearn_train_version = magenelearn_train.train_version
    String? magenelearn_test_version = magenelearn_test.test_version
    File?  split_log = magenelearn_train.split_log
    File? train_tsv = magenelearn_train.train_tsv
    File? test_tsv = magenelearn_train.test_tsv
    File? chisq_top_features = magenelearn_train.chisq_top_features
    File? chisq_log = magenelearn_train.chisq_log
    File? muvr_log = magenelearn_train.muvr_log
    File? muvr_min = magenelearn_train.muvr_min
    File? muvr_max = magenelearn_train.muvr_max
    File? muvr_mid = magenelearn_train.muvr_mid
    File? boruta_log = magenelearn_train.boruta_log
    File? boruta_min = magenelearn_train.boruta_min
    File? boruta_max = magenelearn_train.boruta_max
    File? boruta_mid = magenelearn_train.boruta_mid
    File? final_features_log = magenelearn_train.final_features_log
    File? final_features_test = magenelearn_train.final_features_test
    File? final_features_train = magenelearn_train.final_features_train
    File? train_log = magenelearn_train.train_log
    File? train_model_file = magenelearn_train.train_model_file
    File? test_eval_log = magenelearn_test.test_eval_log
    Array[File]? classification_report = magenelearn_test.classification_report
    Array[File]? confusion_matrix = magenelearn_test.confusion_matrix
    Array[File]? test_predictions_probabilities = magenelearn_test.test_predictions_probabilities
    Array[File]? test_predictions = magenelearn_test.test_predictions
  }
}
version 1.0

import "../tasks/task_versioning.wdl" as task_versioning
import "../tasks/task_magenelearn_train.wdl" as run_magenelearn_train
import "../tasks/task_magenelearn_test.wdl" as run_magenelearn_test

workflow magenelearn_wf {
  input{
    String run_name
    File? external_features
    String? label
    String? group_column
    String mode = "full"
    File? model_file
    File? features_test 
    # meta_file, train_meta, and test_meta are mutually exclusive
    File? meta_file
    File? train_meta
    File? test_meta
  }
  call task_versioning.version_capture{
    input:
  }
  # Validate mutually exclusive metadata inputs and output string due to lack of WDL functionality
  if ((mode == "full" || mode == "train") && length(select_all([meta_file, train_meta, test_meta])) == 1){
    call run_magenelearn_train.magenelearn_train {
      input:
        name = run_name,
        meta_file = meta_file,
        train_meta = train_meta,
        test_meta = test_meta,
        features = external_features,
        label = label,
        group_column = group_column
    }
  }
  if (length(select_all([meta_file, train_meta, test_meta])) != 1){
    String train_input_validation_err = "ERROR: Provide one meta_file, train_meta, or test_meta as they are mututally exclusive"
  }
  # Check for completion of train and mode
  if ((mode == "full" && defined(magenelearn_train.train_model_file)) || (mode == "test" && defined(model_file))){
    call run_magenelearn_test.magenelearn_test {
      input:
        name = run_name,
        model_file = select_first([magenelearn_train.train_model_file, model_file]),
        features_file = select_first([magenelearn_train.muvr_min, magenelearn_train.boruta_min]),
        features_test = select_first([magenelearn_train.final_features_test, features_test]),
        label = label,
        group_column = group_column
    }
  }
  if ((mode == "full" && !defined(magenelearn_train.train_model_file)) || (mode == "test" && !defined(model_file))){
    String test_input_validation_err = "ERROR: No model file provided from either user or train task."
  }
  output {
    # Workflow Outputs
    String magenelearn_wf_version = version_capture.magenelearn_version
    String magenelearn_wf_date = version_capture.date
    # Both errors will be present when a 'full' mode run fails on inputs while only the related error will be returned when test/train are run individually.
    String input_validation_out = if (defined(train_input_validation_err) && defined(test_input_validation_err))
                then select_first([train_input_validation_err]) + "; " + select_first([test_input_validation_err])
                else select_first([train_input_validation_err, test_input_validation_err, "PASS"])
    # Train Outputs
    String? magenelearn_train_version = magenelearn_train.train_version
    File? split_log = magenelearn_train.split_log
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
    # Test Outputs
    String? magenelearn_test_version = magenelearn_test.test_version
    File? test_eval_log = magenelearn_test.test_eval_log
    File? classification_report = magenelearn_test.classification_report
    File? confusion_matrix = magenelearn_test.confusion_matrix
    File? test_predictions_probabilities = magenelearn_test.test_predictions_probabilities
    File? test_predictions = magenelearn_test.test_predictions
  }
}
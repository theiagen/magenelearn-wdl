version 1.0

task magenelearn_test {
  input {
    String name
    # Test and Predict Options
    File? model_file
    File? features_test
    File? features_file
    File? test_metadata
    Boolean predict_only = false
    Boolean? skip_svm_importance
    File? features
    String label = "outcome"
    String group_column = "group"
    # Model-training Options
    String scoring = "balanced_accuracy"
    Int disk_size = 100
    String docker = "us-docker.pkg.dev/general-theiagen/theiagen/magenelearn:0.1.0"
    Int memory = 16
    Int cpu = 4
  }
  command <<<
    # Get version
    python -m pip show maGeneLearn | grep Version | tee VERSION

    output_dir="~{name}_out"

    echo "DEBUG: Checking contents of compressed default models"
    tar -tzf /data/default_model_files.tar.gz   
    # These model files are large so saving the extraction until needed to save time. 
    if [[ ! -f "~{model_file}" ]]; then
      echo "DEBUG: No model_file provided. Extracting default model-file: rfc_random_accuracy_RFC_random.joblib"
      tar -xzf /data/default_model_files.tar.gz
    fi

    maGeneLearn test \
      ~{'--model-file ' + select_first([model_file, "defaults/rfc_random_accuracy_RFC_random.joblib"])} \
      ~{'--features ' + features} \
      ~{'--features-test ' + features_test} \
      --name ~{name} \
      ~{'--label ' + label} \
      ~{'--group-column ' + group_column} \
      ~{'--features ' + features} \
      ~{'--test-metadata ' + test_metadata} \
      ~{'--feature-file ' + features_file} \
      ~{true="--predict-only" false="" predict_only} \
      ~{'--scoring ' + scoring} \
      ~{true="--skip-svm-importance" false="" skip_svm_importance} \
      --output-dir "$output_dir"

      mv "$output_dir"/07_test_eval/*_test_classification_report.tsv "$output_dir"/classification_report.tsv
      mv "$output_dir"/07_test_eval/*_test_confusion_matrix.tsv "$output_dir"/confusion_matrix.tsv

      # Base files have different names based on predict_only flag
      if ! ~{predict_only} ; then
        mv "$output_dir"/07_test_eval/*_test_predictions_probabilities.tsv "$output_dir"/predictions_probabilities.tsv
      else
        mv "$output_dir"/07_test_eval/*_test_predictions.tsv "$output_dir"/predictions.tsv
      fi
  >>>
  output {
    File? test_eval_log = "~{name}_out/07_test_eval/eval_test.log"
    File? classification_report = "~{name}_out/classification_report.tsv"
    File? confusion_matrix = "~{name}_out/confusion_matrix.tsv"
    File? test_predictions_probabilities = "~{name}_out/predictions_probabilities.tsv"
    File? test_predictions = "~{name}_out/predictions.tsv"
    String test_version = read_string("VERSION")
  }
  runtime {
    docker: docker
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk " + disk_size + " SSD"
    disk: disk_size + " GB"
    preemptible: 0
    maxRetries: 3
  }
}
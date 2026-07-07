version 1.0

task magenelearn {
  input {

    String mode
    String name

    # Test and Predict Options
    File? model_file
    File? features_test
    File? features_file
    File? test_metadata
    Boolean? predict_only
    Boolean? skip_svm_importance

    # Training Options
    File? meta_file
    File? train_meta # Either meta train or test are used
    File? test_meta
    File? features
    File? features2
    File? features_train
    String? model

    String label = "outcome"
    String group_column = "group"
    String? lineage_col
    String id_col = "SRA"

    # Feature-selection Options
    Boolean? chisq
    Int k = 100000
    File? chisq_file
    Boolean? muvr
    Boolean? boruta
    File? feature_model
    Boolean? feature_selection_only

    # MUVR-specific Options
    Float dropout_rate = 0.9
    Int muvr_n_repetitions = 10
    Int muvr_n_outer = 5
    Int muvr_n_inner = 4

    # Boruta-specific Options
    Int boruta_perc = 100
    Float boruta_alpha = 0.05
    Int boruta_max_iter = 100

    # Model-training Options
    String? upsampling
    Int? n_iter
    Boolean? no_split
    Int n_splits = 5
    Int n_splits_cv = 7
    String scoring = "balanced_accuracy"
    Int n_jobs = 1 # Defaut to 1 as the tool default is -1
    String? xgb_policy
    String lr_penalty = "l2"
    
    Int disk_size = 100
    String docker = "us-docker.pkg.dev/general-theiagen/theiagen/magenelearn:0.1.0"
    Int memory = 16
    Int cpu = 4
  }
  command <<<
    # Get version
    python -m pip show maGeneLearn | grep Version | tee VERSION

    echo "DEBUG: Checking contents of compressed default models"
    tar -tzf /data/default_model_files.tar.gz   

    # Train meta file selection
    meta_inputs=~{length(select_all([meta_file, train_meta, test_meta]))}
    if [[ "$meta_inputs" -ne 1 ]]; then
      echo "ERROR: meta_file / train_meta / test_meta are mutually exclusive. Please provide only one" >&2
      exit 1
    fi

    # Required train inputs: meta-file / train-meta / test-meta, name
    if [[ "~{mode}" == "train" ]]; then
      maGeneLearn train \
        --name ~{name} \
        ~{'--meta-file ' + meta_file} \
        ~{'--train-meta ' + train_meta} \
        ~{'--test-meta ' + test_meta} \
        ~{'--lineage-col ' + lineage_col} \
        ~{'--id-col ' + id_col} \
        ~{'--features ' + features} \
        ~{'--features2 ' + features2} \
        ~{'--features-train ' + features_train} \
        ~{'--features-test ' + features_test} \
        ~{'--model ' + model} \
        ~{'--feature-model ' + feature_model } \
        ~{'--label ' + label} \
        ~{'--group-column ' + group_column} \
        ~{'--upsampling ' + upsampling} \
        ~{'--lr-penalty ' + lr_penalty} \
        ~{'--xgb-policy ' + xgb_policy} \
        ~{'--scoring ' + scoring} \
        ~{'--n-splits ' + n_splits} \
        ~{'--n-splits-cv ' + n_splits_cv} \
        ~{'--n-iter ' + n_iter} \
        ~{'--n-jobs ' + n_jobs} \
        ~{true="--chisq" false="--no-chisq" chisq} \
        ~{'--k ' + k} \
        ~{'--chisq-file ' + chisq_file} \
        ~{true="--muvr" false="--no-muvr" muvr} \
        ~{true="--boruta" false="--no-boruta" boruta} \
        ~{true="--no-split" false="" no_split} \
        ~{true="--feature-selection-only" false="" feature_selection_only} \
        ~{'--dropout-rate ' + dropout_rate} \
        ~{'--muvr-n-repetitions ' + muvr_n_repetitions} \
        ~{'--muvr-n-outer ' + muvr_n_outer} \
        ~{'--muvr-n-inner ' + muvr_n_inner} \
        ~{'--boruta-perc ' + boruta_perc} \
        ~{'--boruta-alpha ' + boruta_alpha} \
        ~{'--boruta-max-iter ' + boruta_max_iter} \
        --output-dir "~{name}_out"
    # Required test inputs: model-file, name
    elif [[ "~{mode}" == "test" ]]; then

      # These model files are large so saving the extraction until needed to save time. 
      if [[ ! -f "~{model_file}" ]]; then
        echo "DEBUG: No model_file provided. Extracting default model-file: rfc_random_accuracy_RFC_random.joblib"
        tar -xzf /data/default_model_files.tar.gz
      fi

      maGeneLearn test \
        ~{'--model-file ' + select_first([model_file,"defaults/rfc_random_accuracy_RFC_random.joblib"])} \
        ~{'--features-test ' + features_test} \
        --name ~{name} \
        ~{'--label ' + label} \
        ~{'--group-column ' + group_column} \
        ~{'--features ' + features} \
        ~{'--test-metadata ' + test_metadata} \
        ~{'--features-file ' + features_file} \
        ~{true="--predict-only" false="" predict_only} \
        ~{'--scoring ' + scoring} \
        ~{true="--skip-svm-importance" false="" skip_svm_importance} \
        --output-dir "~{name}_out"
    else
      echo "No valid mode selected please choose either 'test' or 'train'." >&2
      exit 1
    fi
  >>>
  output {
    File? split_log = "~{name}_out/00_data_split/split.log"
    File? train_tsv = "~{name}_out/00_data_split/~{name}_train.tsv"
    File? test_tsv = "~{name}_out/00_data_split/~{name}_test.tsv"
    File? chisq_top_features = "~{name}_out/01_chisq/~{name}_top~{k}_features.tsv"
    File? chisq_log = "~{name}_out/01_chisq/chisq.log"
    File? muvr_log = "~{name}_out/02_muvr/muvr.log" # Either muvr or boruta will be output
    File? muvr_min = "~{name}_out/02_muvr/~{name}_muvr_~{model}_min.tsv"
    File? muvr_max = "~{name}_out/02_muvr/~{name}_muvr_~{model}_max.tsv"
    File? muvr_mid = "~{name}_out/02_muvr/~{name}_muvr_~{model}_mid.tsv"
    File? boruta_log = "~{name}_out/02_boruta/boruta.log"
    File? boruta_min = "~{name}_out/02_boruta/~{name}_boruta_~{model}_min.tsv"
    File? boruta_max = "~{name}_out/02_boruta/~{name}_boruta_~{model}_max.tsv"
    File? boruta_mid = "~{name}_out/02_boruta/~{name}_boruta_~{model}_mid.tsv"
    File? final_features_log = "~{name}_out/03_final_features/extract.log"
    File? final_features_test = "~{name}_out/03_final_features/~{name}_test.tsv"
    File? final_features_train = "~{name}_out/03_final_features/~{name}_train.tsv"
    File? train_log = "~{name}_out/04_model/train.log"
    File? train_model_file = "~{name}_out/04_model/~{name}_~{model}_~{upsampling}.joblib"
    String version = read_string("VERSION")
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
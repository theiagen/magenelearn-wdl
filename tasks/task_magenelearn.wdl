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

    String? label
    String? group_column
    String? lineage_col
    String? id_col

    # Feature-selection Options
    Boolean? chisq
    Int? k = 100000
    File? chisq_file
    Boolean? muvr
    Boolean? boruta
    File? feature_model
    Boolean? feature_selection_only

    # MUVR-specific Options
    Float? dropout_rate = 0.9
    Int? muvr_n_repetitions = 10
    Int? muvr_n_outer = 5
    Int? muvr_n_inner = 4

    # Boruta-specific Options
    Int? boruta_perc = 100
    Float? boruta_alpha = 0.05
    Int? boruta_max_iter = 100

    # Model-training Options
    String? upsampling
    Int? n_iter
    Boolean? no_split
    Int? n_splits
    Int? n_splits_cv
    String? scoring 
    Int n_jobs = 1 # Defaut to 1 as the tool default is -1
    String? xgb_policy
    String? lr_penalty
    
    Int disk_size = 100
    String docker = "magenelearn-test:latest"
    Int memory = 16
    Int cpu = 4
  }
  command <<<
    # Get version
    python -m pip show maGeneLearn | grep Version

    maGeneLearn \
      ~{mode} \
      --name ~{name} \
      ~{if defined(meta_file) && mode == "train" then "--meta-file ~{meta_file}" else ""} \
      ~{if defined(train_meta) && mode == "train" then "--train-meta ~{train_meta}" else ""} \
      ~{if defined(test_meta) && mode == "train" then "--test-meta ~{test_meta}" else ""} \
      ~{if defined(lineage_col) then "--lineage-col ~{lineage_col}" else ""} \
      ~{if defined(id_col) then "--id-col ~{id_col}" else ""} \
      ~{if defined(features) then "--features ~{features}" else ""} \
      ~{if defined(features2) then "--features2 ~{features2}" else ""} \
      ~{if defined(features_train) then "--features-train ~{features_train}" else ""} \
      ~{if defined(features_test) then "--features-test ~{features_test}" else ""} \
      ~{if defined(model) then "--model ~{model}" else ""} \
      ~{if defined(feature_model) then "--feature-model ~{feature_model}" else ""} \
      ~{if defined(label) then "--label ~{label}" else ""} \
      ~{if defined(group_column) then "--group-column ~{group_column}" else ""} \
      ~{if defined(upsampling) then "--upsampling ~{upsampling}" else ""} \
      ~{if defined(lr_penalty) then "--lr-penalty ~{lr_penalty}" else ""} \
      ~{if defined(xgb_policy) then "--xgb-policy ~{xgb_policy}" else ""} \
      ~{if defined(scoring) then "--scoring ~{scoring}" else ""} \
      ~{if defined(n_splits) then "--n-splits ~{n_splits}" else ""} \
      ~{if defined(n_splits_cv) then "--n-splits-cv ~{n_splits_cv}" else ""} \
      ~{if defined(n_iter) then "--n-iter ~{n_iter}" else ""} \
      ~{if defined(n_jobs) then "--n-jobs ~{n_jobs}" else ""} \
      ~{true="--chisq" false="--no-chisq" chisq} \
      ~{if defined(k) then "--k ~{k}" else ""} \
      ~{if defined(chisq_file) then "--chisq-file ~{chisq_file}" else ""} \
      ~{true="--muvr" false="--no-muvr" muvr} \
      ~{true="--boruta" false="--no-boruta" boruta} \
      ~{true="--no-split" false="" no_split} \
      ~{if select_first([feature_selection_only, false]) then "--feature-selection-only" else ""} \
      ~{if defined(dropout_rate) then "--dropout-rate ~{dropout_rate}" else ""} \
      ~{if defined(muvr_n_repetitions) then "--muvr-n-repetitions ~{muvr_n_repetitions}" else ""} \
      ~{if defined(muvr_n_outer) then "--muvr-n-outer ~{muvr_n_outer}" else ""} \
      ~{if defined(muvr_n_inner) then "--muvr-n-inner ~{muvr_n_inner}" else ""} \
      ~{if defined(boruta_perc) then "--boruta-perc ~{boruta_perc}" else ""} \
      ~{if defined(boruta_alpha) then "--boruta-alpha ~{boruta_alpha}" else ""} \
      ~{if defined(boruta_max_iter) then "--boruta-max-iter ~{boruta_max_iter}" else ""}
    
  >>>
  output {
    File? split_log = "00_data_split/split.log"
    File? chisq_log = "01_chisq/chisq.log"
    File? muvr_log = "02_muvr/muvr.log"
    File? final_features_log = "03_final_features/extract.log"
    File? train_log = "04_model/train.log"
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
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
  }
}
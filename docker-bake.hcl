variable "base_image" {
  default = "gcc:15.2"
}

variable "git_repo" {
  default = "https://github.com/example/project.git"
}

variable "git_ref" {
  default = "main"
}

variable "cmake_generator" {
  default = "Ninja"
}

variable "cmake_configure_args" {
  default = "-DCMAKE_BUILD_TYPE=Release"
}

variable "cmake_build_args" {
  default = "--parallel"
}

variable "build_target" {
  default = ""
}

variable "export_path" {
  default = "/build"
}

variable "enable_external_zendnn" {
  default = "false"
}

variable "zendnn_git_repo" {
  default = "https://github.com/amd/ZenDNN.git"
}

variable "zendnn_git_ref" {
  default = "master"
}

variable "zendnn_cmake_generator" {
  default = "Ninja"
}

variable "zendnn_cmake_configure_args" {
  default = "-DCMAKE_BUILD_TYPE=Release"
}

variable "zendnn_cmake_build_args" {
  default = "--parallel"
}

group "default" {
  targets = ["artifact"]
}

target "artifact" {
  context    = "."
  dockerfile = "Dockerfile"
  target     = "artifact"

  args = {
    BASE_IMAGE          = "${base_image}"
    GIT_REPO            = "${git_repo}"
    GIT_REF             = "${git_ref}"
    CMAKE_GENERATOR     = "${cmake_generator}"
    CMAKE_CONFIGURE_ARGS = "${cmake_configure_args}"
    CMAKE_BUILD_ARGS    = "${cmake_build_args}"
    BUILD_TARGET        = "${build_target}"
    EXPORT_PATH         = "${export_path}"
    ENABLE_EXTERNAL_ZENDNN = "${enable_external_zendnn}"
    ZENDNN_GIT_REPO     = "${zendnn_git_repo}"
    ZENDNN_GIT_REF      = "${zendnn_git_ref}"
    ZENDNN_CMAKE_GENERATOR = "${zendnn_cmake_generator}"
    ZENDNN_CMAKE_CONFIGURE_ARGS = "${zendnn_cmake_configure_args}"
    ZENDNN_CMAKE_BUILD_ARGS = "${zendnn_cmake_build_args}"
  }
}

target "native-o3" {
  inherits = ["artifact"]
  args = {
    CMAKE_CONFIGURE_ARGS = "-DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS='-O3 -march=native' -DCMAKE_CXX_FLAGS='-O3 -march=native'"
  }
}

target "zen4-o3" {
  inherits = ["artifact"]
  args = {
    CMAKE_CONFIGURE_ARGS = "-DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS='-O3 -march=znver4' -DCMAKE_CXX_FLAGS='-O3 -march=znver4'"
  }
}

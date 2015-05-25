lib_dir = File.expand_path(File.join('..', 'lib'))
$LOAD_PATH.unshift(lib_dir)

require "minitest/autorun"

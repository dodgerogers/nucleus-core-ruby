$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "nucleus_core"
require "minitest/autorun"
require "securerandom"
require "ostruct"

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |rb| require(rb) }

NucleusCoreTestConfiguration.init!

Minitest.after_run { NucleusCore.reset }

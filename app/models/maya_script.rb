# frozen_string_literal: true

# Script subclass for Lammps rendering
class LammpsScript < Script
  def self.model_name
    Script.model_name
  end

  def script_template
    Configuration.maya_script_template
  end

  def renderers
    [
      'arnold', 'default', 'file', 'hw2', 'hw',
      'interBatch', 'sw', 'turtle', 'turtlebake', 'vr'
    ].freeze
  end

  def cores
    Configuration.cores
  end

  def cluster
    Configuration.submit_cluster
  end

  def available_versions
    ['2020-cpu', '2021-2']
  end

  def job_name
    'lammps'
  end
end

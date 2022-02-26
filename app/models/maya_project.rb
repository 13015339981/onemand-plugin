# frozen_string_literal: true

# Project subclass for Lammps Projects
class LammpsProject < Project
  def self.model_name
    Project.model_name
  end

  def scenes
    Dir.glob("#{directory}**.**")
  end

  def script_type
    'LammpsScript'
  end

  def default_script_extra
    ''
  end
end

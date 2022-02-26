# frozen_string_literal: true

# ProjectFactory creates subclasses of Project
class ProjectFactory
  def self.new_project(params)
    case params[:project_type].to_s.downcase
    when 'lammps'
      LammpsProject.new(params.except(:project_type))
    when 'vray'
      VRayProject.new(params.except(:project_type))
    else
      LammpsProject.new(params.except(:project_type))
    end
  end

  def self.lammps_project?(project)
    project.is_a?(LammpsProject)
  end

  def self.vray_project?(project)
    project.is_a?(VRayProject)
  end
end

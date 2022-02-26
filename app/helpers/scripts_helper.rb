# frozen_string_literal: true

module ScriptsHelper
  def normalize_css_str(str)
    str.to_s.sub(' ', '-')
  end

  def version_label(project)
    if ProjectFactory.lammps_project?(project)
      'Lammps'
    elsif ProjectFactory.vray_project?(project)
      'VRay'
    else
      'Lammps'
    end
  end
end

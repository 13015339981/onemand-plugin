# Lammps

[TOC]



## 一、部署

1、下载二进制安装包 [https://github.com/osc/frame-renderer](#ticket/zoom/_blank) 

2、安装包路径 172.16.0.110:/root/test_gui/*.rpm

3、安装插件 rpm -ivh *.rpm

## 二、自定义插件

### 1、目录结构

```
- app
- bin
- CHANGELOG.md
- config
- config.ru
- db 
- docs
- Gemfile
- Gemfile.lock
- gems-build
- jobs
- lib
- LICENSE
- log
- manifest.yml
- packaging 
- public 
- Rakefile
- README.md
- test
- tmp
- vendor
- VERSION
```



### 2、修改文件

#### ①、app 所有的静态文件，

​	Assets 样式文件不做修改。

​	Controller 软件后台代码，修改后台业务逻辑，在project_controller.rb  scripts_controller.rb

​	Helper  工具类，需要增添相应的函数 scripts_helper.rb 

​          Def version_label(project){ /*按格式修改*/  } 

​	Models  作业模板类，修改 maya_project.rb maya_script.rb  project_factory.rb  project.rb  script.rb

​	Maya_script.rb  可以自定义脚本文件名称，读取文件的后缀名、脚本文件路径等。

​	Project_factory.rb  定义Lammps的业务逻辑，修改  new_project()  xxx_project() 函数

```
def self.new_project(params)
  case params[:project_type].to_s.downcase
  when 'maya'
  	MayaProject.new(params.except(:project_type))
  when 'vary'
  	VaryProject.new(params.except(:project_type))
  else
  	VaryProject.new(params.except(:project_type))
  end
end

def self.maya_project?(project)
	project.is_a?(AlphafoldProject)
end
```

替换为

```
def self.new_project(params)
  case params[:project_type].to_s.downcase
  when 'lammps'
  	LammpsProject.new(params.except(:project_type))
  when 'vary'
  	VaryProject.new(params.except(:project_type))
  else
  	VaryProject.new(params.except(:project_type))
  end
end

def self.lammps_project?(project)
	project.is_a?(LammpsProject)
end
```



#### ②、Views 静态页面按前端展示内容进行修改。

```xx.erb
projects目录下《show.html.erb》
<div class="page-header" >
  <h2><%= @project.name %></h2>
  <p><%= @project.description %></p>
</div>
<script>pollSubmissions('<%= @project.id %>')</script>
<div style="display:inline-block">
  <%= link_to '返回', projects_path, class: "btn btn-info" %>
  <%= link_to '编辑', edit_project_path(@project), class: "btn btn-warning" %>
  <%= link_to "打开文件目录", OodAppkit.files.url(path: @project.directory).to_s,
    class: 'btn btn-primary btn-sm', :target => '_blank' %>
</div>
<br><br>
<div id="script-list-view" class="panel panel-default">
  <div class="panel-body" >
    <table id="script-list-table" class="table data-table" >
      <thead>
        <tr>
          <th>名称</th>
          <th>模板</th>
          <th>文件</th>
          <th>编号</th>
          <th>状态</th>
          <th>操作</th>
        </tr>
      </thead>
      <tbody>
        <% @project.scripts.each do |script| %>
          <tr class="script-row" >
            <td><%= script.name %></td>
            <td><%= script.frames %></td>
            <td><%= script.file.nil? ? "not selected" : File.basename(script.file) %></td>
            <td><div id="script-<%= script.id %>-job-id"><%= script.latest_job_id %></div></td>
            <td id="status_label_<%= script.id %>">
              <%= status_label(script.latest_status, script.id) %>
            </td>
            <td>
                <%= link_to "提交", project_script_submit_path(@project, script), :method => :put,
                    class: 'btn btn-success btn-sm', id: "submit-button-" + script.id.to_s %>
                <%= link_to "停止", project_script_stop_job_path(@project, script, script.latest_id),
                    :method => :delete, class: 'btn btn-danger btn-sm disabled', id: "stop-button-" + script.id.to_s, disabled: "disabled" %>
                <%= link_to "编辑", edit_project_script_path(@project, script), :method => :get, class: 'btn btn-info btn-sm'%>
                <%= link_to "删除", project_script_path(@project, script),
                      :method => :delete, class: 'btn btn-danger btn-sm', data: {confirm: "Are you sure?"} %>
                <%= link_to "查看作业结果", project_script_path(@project, script), :method => :get, class: 'btn btn-primary btn-sm'%>
            </td>
          </tr>
        <% end %>
      <tbody>
    </table>
  </div>
</div>
<%= link_to '创建新的作业', new_project_script_path(@project), class: "btn btn-primary" %>
<br><br>
<% if thumbnails(@project.directory).size > 0 %>
<div id="thumbnail-list-view" class="panel panel-default">
  <div class="panel-body" >
    <table id="thumbnail-list-table" class="table data-table" >
      <thead>
        <tr>
          <th>File</th>
          <th>Image</th>
        </tr>
      </thead>
          <%= %>
      <tbody>
        <% images(@project.directory).each do |image| %>
          <tr>
            <td>
            <%-
              basename = File.basename(image)
              dir = File.dirname(image)
            -%>
            <%= link_to(basename, "/pun/sys/files/fs#{dir}/#{url_encode(basename)}?download=1") %>
            <td>
              <img
                class="d-block w-100 thumbnail-zoom"
                src="/pun/sys/files/api/v1/fs<%= image_to_thumbnail(@project.directory, image) %>"
                onClick="window.open(this.src)"
              >
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  <div>
</div>
<% end %>
```

```
Projects 路径下的《new.html.erb》
<div class="page-header" >
  <h2>新建项目</h2>
</div>
<div>
  在新建项目之前，请确保你的脚本文件已上传到服务器 <br>
  你可以按照 <a href="https://docs.hpc.sjtu.edu.cn/studio/alphafold-gui.html">此文档</a>上的说明操作.
  <br><br>
  <% if Configuration.sftp_host %>
  如果您已经安装了 SFTP 客户端，您可以单击
  <a href="sftp://<%= ENV["USER"] %>@<%= Configuration.sftp_host %><%= @project.directory %>/">此处</a> 打开它.
  <br><br>
  <% end %>
</div>
<%= render 'form' %>
```

```
Projects 路径下的  index.html.erb
<div class="page-header" >
  <h2>个人项目</h2>
</div>
<div>
  <div class="btn-group open">
    <a  data-method="get"
        data-toggle="tooltip"
        title="Create a new Project"
        href="<%= new_project_path %>">
    <button type="button" id="new_job_button" class="btn btn-primary" > 新建项目</button></a>
  </div>
</div>
<br>
<br>
<h3>项目</h3>

<div id="submission-list-view" class="panel panel-default">
  <div class="panel-body" >
    <table id="submission-list-table" class="table data-table" >
    <thead>
      <tr>
        <th>项目名称</th>
        <th>操作</th>
      <tr>
    </thead>
    <tbody>
      <% @projects.each do |project| %>
        <tr>
          <td><%= link_to project.name, project_path(project)  %></td>
          <td><%= link_to '进行中...', project_path(project), class: 'btn btn-success btn-sm' %>
          <td><%= link_to '编辑', edit_project_path(project), class: 'btn btn-info btn-sm' %>
          <td><%= link_to '删除', project_path(project), :method => :delete,
            data: {confirm: "Are you sure?"}, class: 'btn btn-danger btn-sm' %>
        <tr>
      <% end %>
</tbody>
  </div>
</div>
```

```
Projects 路径下的 _form.html.erb
<%= bootstrap_form_for @project do |form| %>
  <div class="panel panel-default">
    <div class="panel-heading">
      项目详情
    </div>
    <div class="panel-body", role="main">
      <%= form.select :project_type, ['Lammps'], required: true,label:"项目类型(必录项)" %>
      <%= form.text_field :name, label: 'name', required: true,label:"项目名称(必录项)" %>
      <%= form.text_area :description, label: '描述(非必录项)' %>
      <%= form.text_field :directory,
        label: '目录', 'data-filepicker': 'true',
        'data-target_file_type': 'dirs' %>
    </div>
  </div>
  <p>
    <%= form.submit '保存', class: 'btn btn-primary' %>
    <%= form.button '重置', type: :reset, class: 'btn btn-default' %>
    <%= link_to '返回', projects_path, class: 'btn btn-default' %>
  <p>
<% end %>
```

```
Projects 路径下的 edit.html.erb
<div class="page-header" >
  <h2>编辑项目 <%= @project.name %></h2>
</div>
<div>
  <div class="btn-group open">
    <%= button_to 'Delete',
      project_path(@project),
      method: :delete,
      data: { confirm: 'Are you sure?' },
      class: "btn btn-danger",
      id: "delete_project_button"
    %>
  </div>
</div>
<br>
<%= render 'form' %>
```

```
Scripts 路径下的_form.html.erb 文件
<%= bootstrap_form_for [@project, @script] do |form| %>
    <div class="panel panel-default">
      <div class="panel-heading">
        编辑作业脚本
      </div>
      <div class="panel-body", role="main">
        <%= form.text_field :name, required: true,label:"名称(必录项)" %>

        <%= form.select :version, @script.available_versions, required: true, label: "#{version_label(@project)} 版本号" %>
        <%= form.hidden_field :frames,
          required: false, placeholder: '1-100',value:'1-1',
          pattern: '\d+-\d+', help: "Must be in the form startframe-endframe" %>
        <%= form.hidden_field :camera, required: false, placeholder: 'camera1' %>
        <%= form.select :file, @project.scenes, required: true,label:"脚本文件" %>
         <%= form.hidden_field :accounting_id, required: false, label: 'Chargeback project',
          help: 'the project to charge to',
          placeholder: 'PZS0714' %>
        <!-- hidden cluster field becuase of #17. We're only initially supporting one cluster, which is the
        default cluster. -->
        <%= form.hidden_field :cluster, value: @script.cluster %>
        <%= form.number_field :nodes, required: true, min: 1,label:"核数(必录项)" %>
      <!--  <%= form.select :renderer, @script.renderers, required: false %>-->

        <%= form.text_field :extra, required: false,
            label: '其他参数(非必录项)',
            placeholder: '',
            help: ("#{link_to 'Help Docs', 'https://docs.hpc.sjtu.edu.cn/studio/alphafold-gui.html'}").html_safe %>
        <%= form.number_field :walltime, required: true, help: '以小时为单位计算', min: 1,label:'最大运行时长(必录项)' %>
    <!--    <%= form.hidden_field :email, label: 'Email when finished' %>-->
<!--        <%= form.hidden_field :skip_existing, label: 'Do not render existing frames' %>-->
      </div> <!-- main panel body -->
    </div> <!-- outer panel -->
  <p>
    <%= form.submit '保存', class: 'btn btn-primary' %>
    <%= form.button '重置', type: :reset, class: 'btn btn-default' %>
    <%= link_to '返回', project_path(@project), class: 'btn btn-default' %>
  <p>
<% end %>
```

```
Scripts 路径下的 show.html.erb页面
<div class="page-header" >
  <h2><%= @script.name %></h2>  <!-- but also title type header  -->
</div>
<script>pollForUpdates('<%= @project.id %>', '<%= @script.id %>')</script>
<%= link_to '返回', project_path(@project), class: "btn btn-info" %><br><br>
<h3>所有作业运行结果= @script.name%></h3>
<div id="script-list-view" class="panel panel-default">
  <div class="panel-body" >
    <table id="past-jobs-table" class="table data-table" >
      <tbody>
        <% @script.jobs.each do |job| %>
        <tr><td>
          <!-- the button to minimize the job results      -->
          <button
            id="job-<%= job.id %>-button"
            class="job-result-button job-result-button-<%= normalize_css_str(job.status) %>"
            onclick="toggle('job-<%= job.id %>-container')"
            job_id="<%= job.id %>"
            job_status="<%= job.status %>"
          >
            <%= job.job_id %> [<%= job.status %>]
          </button>

          <!-- containter for the job results div  so it can toggle -->
          <div id="job-<%= job.id %>-container" style="display: none;">
          <!-- the job results div -->
            <div id="job-<%= job.id %>-info" >
              <table class="table table-condensed table-striped">
                <tbody>
                  <tr>
                    <td>作业</td>
                    <td><%= job.job_id %></td>
                  </tr>
                  <tr>
                    <td>输出文件</td>
                    <td>
                      <a href="<%= '/pun/sys/files/fs' + (job&.directory || @project.directory + '/batch_jobs/' + job.job_id) %>">打开文件目录</a></td>
                  </tr>
                  <tr>
                    <td>创建时间</td>
                    <td><%= local_time(job.created_at) %></td>
                  </tr>
                  <tr>
                    <td>最后更新时间</td>
                    <td><%= local_time(job.updated_at) %></td>
                  </tr>
                </tbody>
              </table>
            </div> <!-- job info div -->
          </div> <!-- toggle/hide container -->
        </td></tr>
        <% end %>
      </tbody>
    </table>
  </div>
</div>
```

#### ③、bin 可执行文件

```
ENV['RAILS_RELATIVE_URL_ROOT'] ||= '/pun/sys/frame-renderer' if ENV['RAILS_ENV'] == 'production'
```

替换为

```
ENV['RAILS_RELATIVE_URL_ROOT'] ||= '/pun/sys/lammps' if ENV['RAILS_ENV'] == 'production'
```

#### ④、config 环境配置文件

```
root ||= "~/#{ENV['OOD_PORTAL'] || 'ondemand'}/data/#{ENV['APP_TOKEN'] || 'sys/frame-renderer'}"
```

替换为

```
root ||= "~/#{ENV['OOD_PORTAL'] || 'ondemand'}/data/#{ENV['APP_TOKEN'] || 'sys/lammps'}"
```

initialzers 文件中的 init_db_types.db 修改如下内容

```
if File.exist?(db) && !File.zero?(db) && columns_exist?
  Project.where(type: nil).update_all(type: 'MayaProject')
  Script.where(type: nil).update_all(type: 'MayaScript')
end
```

替换为

```
if File.exist?(db) && !File.zero?(db) && columns_exist?
  Project.where(type: nil).update_all(type: 'LammpsProject')
  Script.where(type: nil).update_all(type: 'LammpsScript')
end
```

#### ⑤、jobs/video_jobs/maya_submit.sh.erb     slurm提交作业脚本模板，

```
#!/bin/bash
# set the resources requests. because it's Slurm, we just use --exclusive
# instead of caring about cores
#SBATCH --job-name=session
#SBATCH --partition=dgx2
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=<%= 6*nodes %>
#SBATCH --gres=gpu:<%= nodes %>
#SBATCH --output=%j.out
#SBATCH --error=%j.err
#
echo "starting at $(date)"
<%
  groups = OodSupport::Process.groups.map(&:name)
%>
RENDERER="<%= renderer %>"
EXTRA_ARGS="<%= extra %>"
PRJ_DIR="<%= project_dir %>"
SKIP_EXISTING="-skipExistingFrames <%= skip_existing %>"
SCRIPT_FILE="<%=file%>"
TYPE="<%= type%>"
echo $PRJ_DIR
echo $SCRIPT_FILE
echo "AlphaFold start at $(date)"
cp $SCRIPT_FILE ./test.fasta
echo "true-1011"
module purge
module load alphafold
module list
echo $PWD
run_af2  $PWD  --preset=casp14  test.fasta  --max_template_date=2021-09-12
echo "AlphaFold ended at $(date)"
[ -n "$SLURM_ARRAY_TASK_ID" ] || SLURM_ARRAY_TASK_ID=1
#echo "executing: ${CMD[@]} <%= Shellwords.escape(file) %>"
echo "on host: $(hostname)"
echo "with modules:"
module list
echo "ended at $(date)"
echo "ended with status $STATUS"
exit $STATUS
```

#### ⑥、packaging 环境配置文件

```
%global repo_name frame_renderer
%global app_name frame_renderer
```

替换为

```
%global repo_name lammps
%global app_name lammps
```

#### ⑦、Public/assets 公共配置文件

将application-297033af578b628352b99f89d6735fc57fc8ad8b456300b46c0ed745fdfb6146.js 文件中的 frame_renderer 替换为 lammps 

#### ⑧、/var/www/ood/apps/sys/lammps 该路径下，新增 icon.png logo文件

## 三、常见问题

#### 1、A problem occurred while initializing your data for this app 

问题原因：本地数据库文件被删除，和远程服务器里的缓存数据不匹配。

本地数据库： ondemand/data/sys/ 

解决措施： 删除数据库文件，若有重要信息记得备份。

删除远程服务器缓存 

```
rm -rf /var/tmp/ondemand-nginx/username/
```

 ![new_project](/docs/imgs/question1.png)

#### 2、We’re sorry,but something went wrong.

问题原因：①、静态页面修改后与缓存文件不一致。

​					②、后台代码有误。

解决措施：针对原因一： 清除远程缓存文件即可。

```
rm -rf /var/tmp/ondemand-nginx/username/
```

针对原因二： 查看日志文件 /var/log/ondemand-nginx/username/error.log

​                          根据提示的信息进行修改逻辑后台代码。

 ![new_project](/docs/imgs/question2.png)
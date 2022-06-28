# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

Rails.application.load_tasks

desc "Export pipelines from Pipedrive"
task :pipe_export do
  p "invoke PipelineExportService"
  PipelineExportService.export "Z-Mannheim-Region"
  p "invocation finished"
end

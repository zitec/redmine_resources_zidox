module RedmineResources
  module Patches
    module IssuePatch
      def self.included(base)
        base.send :include, InstanceMethods
        base.class_eval do
          has_many :issue_resources, dependent: :destroy
          has_many :resources, through: :issue_resources
          after_save :set_issue_resource
        end
      end

      module InstanceMethods
        def resources_with_divisions
          IssueResource.includes(resource: :division)
            .where(issue_id: self.id)
            .reduce({}) do |total, element|
              division_name = element.resource.division.name
              total[division_name] = [] unless total[division_name]
              total[division_name] << element
              total
            end
        end

        def set_issue_resource
          custom_field_id = Setting.plugin_redmine_resources[:custom_field_id]
          resource_id = resource_id_from_settings
          default_resource = Resource.where(id: resource_id).first
          return unless default_resource
          custom_field = custom_values.where(custom_field_id: custom_field_id)
            .first
          return unless custom_field
          custom_value = custom_field.value
          if custom_value.blank? || custom_value == '0'
            issue_resources.where(resource_id: default_resource.id).destroy_all
          else
            resource = issue_resources.where(resource_id: default_resource.id)
              .first_or_initialize
            resource.assign_attributes(estimation: custom_value.to_i)
            resource.save!
          end
        end

        private

        def resource_id_from_settings
          setting_name = "plugin_redmine_resources_project_#{ project_id }"
          begin
            project_settings = Setting.send setting_name
          rescue NoMethodError
            Setting.define_setting setting_name, 'serialized' => true
            project_settings = Setting.send setting_name
          end
          project_settings = {} if !project_settings || project_settings.blank?
          if project_settings['custom'] == '1'
            project_settings['resource_id']
          else
            Setting.plugin_redmine_resources[:resource_id]
          end
        end
      end
    end
  end
end

base = Issue
patch = RedmineResources::Patches::IssuePatch
base.send :include, patch unless base.included_modules.include? patch

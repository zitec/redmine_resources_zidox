require File.expand_path('../../test_helper', __FILE__)

class IssuePatchTest < ActiveSupport::TestCase
  def create_parent_and_child(hours: 0, manual: false)
    @parent = build_issue_with @root_tracker
    @parent.manually_added_resource_estimation = manual
    @parent.save!
    @child = build_issue_with @child_tracker, parent: @parent,
      estimated_hours: @hours
    @child.save!
  end

  setup do
    @hours = 12
    create_base_setup
  end

  test 'Issue is patched with RedmineResources::Patches::IssuePatch' do
    patch = RedmineResources::Patches::IssuePatch
    assert_includes Issue.included_modules, patch
    %i(resources_with_divisions track_estimation_change
      calculate_resource_estimation_for_self recalculate_resources_for
      calculate_resource_estimation_for_parent recalculate_from_children
      ensure_current_issue_resource_for determine_resource_type_id
      update_estimation_for issue_gets_resources?).each do |method|
        assert_includes Issue.instance_methods, method
      end
  end

  # manually_added_resource_estimation = false
  test 'issue without estimation creates no resource' do
    issue = build_issue_with @root_tracker
    issue.save!
    assert_empty issue.issue_resource.all
  end

  test 'issue with estimation creates one resource' do
    issue = build_issue_with @root_tracker, estimated_hours: @hours
    issue.save!
    resources = issue.issue_resource.all
    assert_not_empty resources
    assert resources.size == 1
    resource = resources[0]
    assert_instance_of IssueResource, resource
    assert resource.estimation == @hours
  end

  test 'issue with a child gets an estimation' do
    create_parent_and_child
    resources = @parent.issue_resource.all
    assert_not_empty resources
    assert resources.size == 1
    resource = resources[0]
    assert_instance_of IssueResource, resource
    assert resource.estimation == @hours
  end

  test 'issue with a killed child looses the estimation' do
    create_parent_and_child
    @child.status = @status_killed
    @child.save!
    assert_empty @parent.issue_resource.all
  end

  test 'issue with a revived child gets the estimation back' do
    create_parent_and_child
    @child.status = @status_killed
    @child.save!
    assert_empty @parent.issue_resource.all
    @child.status = @status_new
    @child.save!
    resources = @parent.issue_resource.all
    assert_not_empty resources
    assert resources.size == 1
    resource = resources[0]
    assert_instance_of IssueResource, resource
    assert resource.estimation == @hours
  end

  # manually_added_resource_estimation = true
  test 'issues with manual estimation do not get affected by children' do
    create_parent_and_child manual: true
    assert_empty @parent.issue_resource.all
  end

  test 'issues with manual estimation keep their estimation' do
    parent = build_issue_with @root_tracker
    parent.manually_added_resource_estimation = true
    parent.save!
    parent_estimation = 1
    issue_resource = IssueResource.create! issue_id: parent.id,
      resource_id: @resource.id, estimation: parent_estimation
    @child = build_issue_with @child_tracker, parent: parent,
      estimated_hours: @hours
    @child.save!
    resources = parent.issue_resource.all
    assert_not_empty resources
    assert resources.size == 1
    resource = resources[0]
    assert_instance_of IssueResource, resource
    assert resource.estimation == parent_estimation
  end
end
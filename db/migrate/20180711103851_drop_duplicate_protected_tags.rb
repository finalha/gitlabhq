# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropDuplicateProtectedTags < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  BATCH_SIZE = 1000

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    include ::EachBatch
  end

  class ProtectedTag < ActiveRecord::Base
    self.table_name = 'protected_tags'
  end

  def up
    Project.each_batch(of: BATCH_SIZE) do |projects|
      ids = ProtectedTag
        .where(project_id: projects.select(:id))
        .group(:name, :project_id)
        .select('max(id)')

      ProtectedTag
        .where(project_id: projects)
        .where.not(id: ids)
        .delete_all
    end
  end

  def down
  end
end
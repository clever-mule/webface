Sequel.migration do
  change do
    create_table :participations do
      Bigint :project_rcn
      Bigint :project_id
      String :role, size: 127

      foreign_key :organization_id, :organizations
      foreign_key [:project_rcn, :project_id], :projects
    end
  end
end

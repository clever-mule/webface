Sequel.migration do
  change do
    create_table :organizations do
      Bigint :id, primary_key: true
      String :name, text: true
      String :short_name, size: 255
      String :activity_type, size: 11
      String :country, size: 5
    end
  end
end

Sequel.migration do
  change do
    create_table :projects do
      Bigint :rcn
      Bigint :id
      String :acronym, size: 127
      String :status, size: 127
      String :title, size: 2047
      Date :start_date
      Date :end_date

      primary_key [:rcn, :id]
    end
  end
end

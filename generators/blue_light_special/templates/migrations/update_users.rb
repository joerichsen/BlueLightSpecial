class BlueLightSpecialUpdateUsers<%= schema_version_constant %> < ActiveRecord::Migration
  def self.up
<%
      existing_columns = ActiveRecord::Base.connection.columns(:users).collect { |each| each.name }
      columns = [
        [:role,                 't.string :role, :limit => 50'],
      ].delete_if {|c| existing_columns.include?(c.first.to_s)}
-%>
    change_table(:users) do |t|
<% columns.each do |c| -%>
      <%= c.last %>
<% end -%>
    end

  end

  def self.down
    change_table(:users) do |t|
<% unless columns.empty? -%>
      t.remove <%= columns.collect { |each| ":#{each.first}" }.join(',') %>
<% end -%>
    end
  end
end

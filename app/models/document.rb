class Document < ActiveRecord::Base
  has_many :user_has_accesses, foreign_key: :document_id, :dependent => :destroy
  has_many :view_accesses, -> { where(access_type: 0) }, class_name: 'UserHasAccess', foreign_key: :document_id
  has_many :edit_accesses, -> { where(access_type: 1) }, class_name: 'UserHasAccess', foreign_key: :document_id
	has_many :users, through: :user_has_accesses, source: :user
	has_many :document_types, through: :document_has_types
	has_many :document_has_types, :dependent => :destroy
	has_many :child_documents, class_name: 'Document', foreign_key: :parent_directory, :dependent => :destroy
  belongs_to :document_folder, class_name: 'Document', foreign_key: :parent_directory
  belongs_to :owner, class_name: 'User', foreign_key: :owner_id
  has_one :file_info, class_name: 'FileInfo', foreign_key: 'document_id', :dependent => :destroy

  validates :description, length: { maximum: 256 }
  validates :tags, length: { maximum: 256 }

  scope :with_matched_field, ->(value, field) {fields=field.split(" "); where(Document.arel_table[fields[0]].matches('%' + value + '%')) || where(Document.arel_table[fields[1]].matches('%' + value + '%')) }

  def save_with_file(file)
    begin
      transaction do
          self.save!
          file.document_id = self.id
          file.save!
          return true
      end
    rescue ActiveRecord::StatementInvalid
      #error
    rescue
      return false
    end
  end

  def as_json(options = {})
    { id: id, text: title, children: doc_type == 0, icon: doc_type == 0 ? 'jstree-folder' : 'jstree-file' }
  end
end

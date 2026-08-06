-- Users
DEFINE TABLE users SCHEMAFULL;

DEFINE FIELD name ON TABLE users TYPE string;

-- Base items (no parent/ownership stored here; they are edges)
DEFINE TABLE items SCHEMAFULL;

DEFINE FIELD name ON TABLE items TYPE string;
DEFINE FIELD hash ON TABLE items TYPE string;
DEFINE FIELD kind ON TABLE items TYPE string; -- file|directory|page|project|api_doc|link|...
DEFINE FIELD slug ON TABLE items TYPE option<string>;

DEFINE FIELD created_at ON TABLE items TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON TABLE items TYPE datetime DEFAULT time::now();

-- Tree (parent -> child)
DEFINE TABLE contains SCHEMAFULL TYPE RELATION IN items OUT items;

-- Each child has exactly one parent
DEFINE INDEX contains_child_unique ON TABLE contains FIELDS out UNIQUE;
-- Prevent duplicate edge records for same parent-child
DEFINE INDEX contains_pair_unique  ON TABLE contains FIELDS in, out UNIQUE;

-- Ownership (user -> item), each item has exactly one owner (reverse is native via graph)
DEFINE TABLE owns SCHEMAFULL TYPE RELATION IN users OUT items;

-- Each item has exactly one owner edge
DEFINE INDEX owns_item_unique ON TABLE owns FIELDS out UNIQUE;
-- Prevent duplicate owner edges for same (user,item)
DEFINE INDEX owns_pair_unique ON TABLE owns FIELDS in, out UNIQUE;

-- Subtypes (Model B) : 1-1 with items, via UNIQUE on item

-- file
DEFINE TABLE items_file SCHEMAFULL;
DEFINE FIELD item ON TABLE items_file TYPE record<items>;
DEFINE FIELD file_kind ON TABLE items_file TYPE string; -- asset|raw-data
DEFINE FIELD mime_type ON TABLE items_file TYPE option<string>;
DEFINE FIELD bytes_size ON TABLE items_file TYPE option<int>;
DEFINE FIELD stored_uri ON TABLE items_file TYPE option<string>; -- if you store externally

DEFINE INDEX items_file_one_per_item ON TABLE items_file FIELDS item UNIQUE;

-- directory
DEFINE TABLE items_directory SCHEMAFULL;
DEFINE FIELD item ON TABLE items_directory TYPE record<items>;
DEFINE FIELD hint ON TABLE items_directory TYPE option<string>;

DEFINE INDEX items_directory_one_per_item ON TABLE items_directory FIELDS item UNIQUE;

-- page
DEFINE TABLE items_page SCHEMAFULL;
DEFINE FIELD item ON TABLE items_page TYPE record<items>;
DEFINE FIELD ext ON TABLE items_page TYPE string; -- md|mdx|html|...
DEFINE FIELD title ON TABLE items_page TYPE option<string>;
DEFINE FIELD rendered_format ON TABLE items_page TYPE option<string>; -- html|text|...
DEFINE FIELD rendered_uri ON TABLE items_page TYPE option<string>; -- if you store output externally

DEFINE INDEX items_page_one_per_item ON TABLE items_page FIELDS item UNIQUE;

-- project
DEFINE TABLE items_project SCHEMAFULL;
DEFINE FIELD item ON TABLE items_project TYPE record<items>;
DEFINE FIELD repo_url ON TABLE items_project TYPE string;
DEFINE FIELD docs_root_path ON TABLE items_project TYPE string;

DEFINE INDEX items_project_one_per_item ON TABLE items_project FIELDS item UNIQUE;

-- api docs
DEFINE TABLE items_api_doc SCHEMAFULL;
DEFINE FIELD item ON TABLE items_api_doc TYPE record<items>;
DEFINE FIELD format ON TABLE items_api_doc TYPE string; -- openapi|...
DEFINE FIELD openapi ON TABLE items_api_doc FLEXIBLE TYPE object;

DEFINE INDEX items_api_doc_one_per_item ON TABLE items_api_doc FIELDS item UNIQUE;

-- link (symlink-like)
DEFINE TABLE items_link SCHEMAFULL;
DEFINE FIELD item ON TABLE items_link TYPE record<items>;
DEFINE FIELD link_mode ON TABLE items_link TYPE string; -- symlink|shortcut
DEFINE FIELD target_path_hint ON TABLE items_link TYPE option<string>;

DEFINE INDEX items_link_one_per_item ON TABLE items_link FIELDS item UNIQUE;

-- relation for symlink target: link item -> target item
DEFINE TABLE link_points_to SCHEMAFULL TYPE RELATION IN items OUT items;

-- each link points to exactly one target
DEFINE INDEX link_points_to_from_unique ON TABLE link_points_to FIELDS in UNIQUE;
-- prevent duplicate (link,target)
DEFINE INDEX link_points_to_pair_unique ON TABLE link_points_to FIELDS in, out UNIQUE;

-- Vector chunks for semantic search / RAG
DEFINE TABLE item_chunks SCHEMAFULL;

DEFINE FIELD page_item ON TABLE item_chunks TYPE record<items>; -- ideally items_page
DEFINE FIELD chunk_index ON TABLE item_chunks TYPE int;

DEFINE FIELD text ON TABLE item_chunks TYPE string;
DEFINE FIELD metadata ON TABLE item_chunks FLEXIBLE TYPE object;

-- embedding vector
DEFINE FIELD embedding ON TABLE item_chunks TYPE array<float>;

-- uniqueness per page+chunk
DEFINE INDEX item_chunks_page_chunk_unique ON TABLE item_chunks
  FIELDS page_item, chunk_index UNIQUE;

-- HNSW index (DIMENSION را با بعدِ embedding مدل خودت یکسان کن)
DEFINE INDEX item_chunks_embedding_hnsw ON TABLE item_chunks
  FIELDS embedding
  HNSW DIMENSION 3072
  DIST COSINE
  TYPE F32;


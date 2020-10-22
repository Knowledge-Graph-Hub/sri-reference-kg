# All artifacts of the build should be preserved
.SECONDARY:

DATA_DIR=data
OUTPUT_DIR=data-parsed
PROCESSES=1
NEO4J_DATA_DIR=`pwd`/neo_data
SUFFIX=build
DATA_VERSION=202009
KG_VERSION=0.3.0

print-vars:
	@echo "======================================================="
	@echo "Data directory (DATA_DIR): $(DATA_DIR)"
	@echo "Data version (DATA_VERSION): $(DATA_VERSION)"
	@echo "Output directory (OUTPUT_DIR): $(OUTPUT_DIR)"
	@echo "KG Version (KG_VERSION): $(KG_VERSION)"
	@echo "Neo4j data directory (NEO4J_DATA_DIR): $(NEO4J_DATA_DIR)"
	@echo "Suffix for generated artifacts (SUFFIX): $(SUFFIX)"
	@echo "Number of processes (PROCESSES): $(OUTPUT_DIR)"
	@echo "======================================================="

install:
	pip install --no-cache-dir --force-reinstall -r requirements.txt

prepare-transform-yaml: print-vars
	@sed 's/@DATA_DIR@/$(DATA_DIR)/g' transform.yaml | sed 's/@OUTPUT_DIR@/$(OUTPUT_DIR)/g' | sed 's/@VERSION@/$(DATA_VERSION)/g' | sed 's/@KG_VERSION@/$(KG_VERSION)/g' > transform_$(SUFFIX).yaml

prepare-merge-yaml: print-vars
	@sed 's/@DATA_DIR@/$(OUTPUT_DIR)/g' merge.yaml | sed 's/@OUTPUT_DIR@/$(OUTPUT_DIR)/g' | sed 's/@VERSION@/$(DATA_VERSION)/g' | sed 's/@KG_VERSION@/$(KG_VERSION)/g' > merge_$(SUFFIX).yaml

transform: prepare-transform-yaml
	@echo "Running kgx to transform data in $(DATA_DIR) into TSVs and write to $(OUTPUT_DIR)"
	kgx transform --processes $(PROCESSES) --transform-config transform_$(SUFFIX).yaml > kgx_transform_$(SUFFIX).log 2>&1

merge: prepare-merge-yaml
	@echo "Running kgx to merge data in $(OUTPUT_DIR) to create a merged graph and write to $(OUTPUT_DIR)"
	kgx merge --processes $(PROCESSES) --merge-config merge_$(SUFFIX).yaml > kgx_merge_$(SUFFIX).log 2>&1

neo4j-docker: print-vars
	@echo "Creating directory $(NEO4J_DATA_DIR)"
	@mkdir $(NEO4J_DATA_DIR)
	@echo "Creating a Neo4j Docker container"
	docker run -d -p 8484:7474 -p 8888:7687 --env NEO4J_AUTH=neo4j/test --volume=$(NEO4J_DATA_DIR):/data --memory=80G neo4j:3.4.15

neo4j-upload: neo4j-docker
	@echo "Running kgx to upload graph to Neo4j container"
	kgx neo4j-upload --uri http://localhost:8484 --username neo4j --password test --input-format tsv $(OUTPUT_DIR)/sri-reference-kg-@KG_VERSION@_nodes.tsv $(OUTPUT_DIR)/sri-reference-kg-@KG_VERSION@_edges.tsv >& kgx_neo4j_upload_$(SUFFIX).log
	@echo "Creating $(NEO4J_DATA_DIR)_$(SUFFIX).tar.gz archive..."
	tar -cvzf $(NEO4J_DATA_DIR)_$(SUFFIX).tar.gz -C $(NEO4J_DATA_DIR) .

all: transform merge neo4j-upload
	@echo "Workflow complete!"

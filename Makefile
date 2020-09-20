# All artifacts of the build should be preserved
.SECONDARY:

DATA_DIR=monarch-data
OUTPUT_DIR=monarch-data-parsed
PROCESSES=1
NEO4J_DATA_DIR=`pwd`/neo_data
SUFFIX=build
VERSION=202009

print-vars:
	@echo "======================================================="
	@echo "Data directory (DATA_DIR): $(DATA_DIR)"
	@echo "Output directory (OUTPUT_DIR): $(OUTPUT_DIR)"
	@echo "Neo4j data directory (NEO4J_DATA_DIR): $(NEO4J_DATA_DIR)"
	@echo "Suffix for generated artifacts (SUFFIX): $(SUFFIX)"
	@echo "Number of processes (PROCESSES): $(OUTPUT_DIR)"
	@echo "======================================================="

install:
	pip install --no-cache-dir --force-reinstall -r requirements.txt

prepare-transform-yaml: print-vars
	@sed 's/@DATA_DIR@/$(DATA_DIR)/g' monarch_transform.yaml | sed 's/@OUTPUT_DIR@/$(OUTPUT_DIR)/g' | sed 's/@VERSION@/202009/g' > monarch_transform_$(SUFFIX).yaml

prepare-merge-yaml: print-vars
	@sed 's/@DATA_DIR@/$(OUTPUT_DIR)/g' monarch_merge.yaml | sed 's/@OUTPUT_DIR@/$(OUTPUT_DIR)/g' | sed 's/@VERSION@/202009/g' > monarch_merge_$(SUFFIX).yaml

transform: prepare-transform-yaml
	@echo "Running kgx to transform data in $(DATA_DIR) into TSVs and write to $(OUTPUT_DIR)"
	kgx merge --processes $(PROCESSES) monarch_transform_$(SUFFIX).yaml >& kgx_transform_$(SUFFIX).log

merge: prepare-merge-yaml
	@echo "Running kgx to merge data in $(OUTPUT_DIR) to create a merged graph and write to $(OUTPUT_DIR)"
	kgx merge --processes $(PROCESSES) monarch_merge_$(SUFFIX).yaml >& kgx_merge_$(SUFFIX).log

neo4j-docker: print-vars
	@echo "Creating directory $(NEO4J_DATA_DIR)"
	@mkdir $(NEO4J_DATA_DIR)
	@echo "Creating a Neo4j Docker container"
	docker run -d -p 8484:7474 -p 8888:7687 --env NEO4J_AUTH=neo4j/test --volume=$(NEO4J_DATA_DIR):/data --memory=80G neo4j:3.4.15

neo4j-upload: neo4j-docker
	@echo "Running kgx to upload graph to Neo4j container"
	kgx neo4j-upload --uri http://localhost:8484 --username neo4j --password test --input-format tsv $(OUTPUT_DIR)/monarch-kg_nodes.tsv $(OUTPUT_DIR)/monarch-kg_edges.tsv >& kgx_neo4j_upload_$(SUFFIX).log
	@echo "Creating $(NEO4J_DATA_DIR)_$(SUFFIX).tar.gz archive..."
	tar -cvzf $(NEO4J_DATA_DIR)_$(SUFFIX).tar.gz -C $(NEO4J_DATA_DIR) .

all: transform merge neo4j-upload
	@echo "Workflow complete!"

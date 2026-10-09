# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {}
# META }

# MARKDOWN ********************

# # nb_clean_silver
# Reads `sales_raw` from the bronze workspace of the same environment, removes
# duplicates and invalid rows, and overwrites `lh_silver/Tables/sales`.
#
# The bronze workspace is derived from the current one by naming convention
# (`<project>-silver-<env>` -> `<project>-bronze-<env>`), so no environment-specific
# IDs live in the repository.

# CELL ********************

from pyspark.sql import functions as F
import sempy.fabric as fabric

current_ws = notebookutils.runtime.context["currentWorkspaceName"]
bronze_ws = current_ws.replace("-silver-", "-bronze-")
bronze_ws_id = fabric.resolve_workspace_id(bronze_ws)

bronze = notebookutils.lakehouse.get("lh_bronze", bronze_ws_id)
silver = notebookutils.lakehouse.get("lh_silver")

source = f"{bronze.properties['abfsPath']}/Tables/sales_raw"
target = f"{silver.properties['abfsPath']}/Tables/sales"
print(f"{current_ws}: {source} -> {target}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

clean = (
    spark.read.format("delta").load(source)
    .dropDuplicates(["order_id"])
    .filter((F.col("amount") > 0) & F.col("customer_id").isNotNull())
    .drop("_ingested_at")
)

clean.write.format("delta").mode("overwrite").option("overwriteSchema", "true").save(target)
print(f"Wrote {clean.count()} rows to {target}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

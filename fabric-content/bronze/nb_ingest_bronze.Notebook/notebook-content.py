# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {}
# META }

# MARKDOWN ********************

# # nb_ingest_bronze
# Generates fake sales data and appends it to `lh_bronze/Tables/sales_raw`.
#
# The notebook does not depend on a default lakehouse: it resolves `lh_bronze` in the
# workspace it runs in, so the same file works in dev, test and prod without
# environment-specific bindings in `parameter.yml`.

# PARAMETERS CELL ********************

rows = 50000

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

from pyspark.sql import functions as F

lakehouse = notebookutils.lakehouse.get("lh_bronze")
target = f"{lakehouse.properties['abfsPath']}/Tables/sales_raw"

df = (
    spark.range(rows)
    .withColumn("order_id", F.expr("uuid()"))
    .withColumn("order_date", F.expr("date_sub(current_date(), cast(rand() * 365 as int))"))
    .withColumn("customer_id", (F.rand() * 5000).cast("int"))
    .withColumn("amount", F.round(F.rand() * 500, 2))
    .withColumn("_ingested_at", F.current_timestamp())
    .drop("id")
)

df.write.format("delta").mode("append").save(target)
print(f"Appended {rows} rows to {target}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# Production Dockerfile for Google Cloud Run
FROM odoo:17.0

USER root

# Install additional system packages
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Google Cloud SQL Proxy
RUN curl -o /usr/local/bin/cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 \
    && chmod +x /usr/local/bin/cloud_sql_proxy

# Copy custom addons
COPY ./addons /mnt/extra-addons

# Copy requirements and install Python packages
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Install additional production packages
RUN pip install --no-cache-dir \
    google-cloud-sql \
    psycopg2-binary \
    redis

# Copy production configuration
COPY ./config/odoo-production.conf /etc/odoo/odoo.conf

# Create startup script
COPY ./gcp/startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

USER odoo

EXPOSE 8069

# Use startup script as entrypoint
CMD ["/usr/local/bin/startup.sh"]
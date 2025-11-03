FROM odoo:17.0

USER root

# Install additional system packages if needed
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy custom addons
COPY ./addons /mnt/extra-addons

# Copy requirements and install Python packages
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Copy configuration
COPY ./config/odoo.conf /etc/odoo/odoo.conf

USER odoo

EXPOSE 8069 8072
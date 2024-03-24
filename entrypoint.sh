#!/bin/bash

echo "Waiting for database to be ready..."
until python3 manage.py makemigrations; do
	echo "Database is unavailable - sleeping"
	sleep 1
done

# add timeout to wait for database
timeout 30s bash -c 'until echo > /dev/tcp/db/5432; do sleep 1; done'
echo "Database is ready - executing command"

python3 manage.py migrate
python3 manage.py collectstatic --noinput

# idempotent check for admin user
if ! python3 manage.py shell -c "from django.contrib.auth.models import User; print(User.objects.filter(username='admin').exists())" | grep 'True'; then
	python3 manage.py createhorillauser --first_name admin --last_name admin --username admin --password admin --email admin@example.com --phone 1234567890
else
	echo "Admin user already exists."
fi

gunicorn --bind 0.0.0.0:8000 horilla.wsgi:application

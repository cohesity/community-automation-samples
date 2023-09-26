#!/usr/bin/env python
"""Certificate Improvement"""

import time
import requests
import sys
import os
import json
import urllib3
# import pyhesity wrapper module
from pyhesity import *

### ignore unsigned certificates
import requests.packages.urllib3

requests.packages.urllib3.disable_warnings()

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

import logging

### command line arguments
import argparse
parser = argparse.ArgumentParser()

parser.add_argument('-c', '--cluster', type=str, default=None)


args = parser.parse_args()

clusterfile = args.cluster


# Configure the logging settings
log_file_path = "cert.log"  # Set the path to the log file
log_level = logging.DEBUG  # Set the desired log level

# Create a logger
logger = logging.getLogger("cert")
logger.setLevel(log_level)

# Create a file handler and set the log level
file_handler = logging.FileHandler(log_file_path)
file_handler.setLevel(log_level)

# Create a console handler and set the log level
console_handler = logging.StreamHandler()
console_handler.setLevel(log_level)

# Create a formatter and set it for both handlers
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)
console_handler.setFormatter(formatter)

# Add the handlers to the logger
logger.addHandler(file_handler)
logger.addHandler(console_handler)



def get_cluster_version(ip, cluster_detail):
    """Function to get cluster software version

    Args:
        cluster_detail (Dict): Cluster detail with IP, Username, Password

    Returns:
        Dict | None: Returns information about Cohesity Cluster
    """

    # Supported release version for cert improvement
    supported_version = ['6.8.1_u5_release']

    try:
        # Send an HTTP GET request with the cookies
        response = api('get', '/public/cluster')

        software_version = response['clusterSoftwareVersion'].split("-")[0]
        if software_version not in supported_version:
            logger.error(f"Cluster "+ip+" is not in Supported version")
            return None
        logger.info(f"Cluster "+ip+" is in supported version")
        return response

    except requests.exceptions.RequestException as e:
        logger.error(f"An error occurred: {e}")


def ca_keys():
    """ Function to get Cohesity CA keys from cluster

    Returns:
        String: PrivateKey, Certificate
    """

    try:
        # Send an HTTP GET request for ca-keys
        response = api('get', 'cert-manager/ca-keys', v=2)

        if response is not None:
            logger.info("Fetched Cohesity CA keys from Cluster")
            return response['privateKey'], response['caChain']
        else:
            logger.error(f"ca-keys request failed!")
            exit(1)

    except requests.exceptions.RequestException as e:
        logger.error(f"An error occurred: {e}")
        exit(1)


def bootstrap_targets(target_list, cert, privateKey):
    """ Function to bootstrap cohesity CA keys to target clusters

    Args:
        target_list (List): List of Target Clusters
        cert (Srting): Primary Cluster Certificate
        privateKey (String): Primary Cluster PrivateKey
    """

    bootstrap = input("Continue bootstrapping clusters (Y/N)? ").strip().lower()
    if bootstrap != "y" and bootstrap != "yes":
        logger.info("Skipping cluster bootstrap!!")

    for target in target_list:
        target_mfa = None
        target_password = None

        logger.info("Bootstrapping started on Cluster "+ target['ip'])

        target_password = target.get('password')
        target_mfa = target.get('mfaCode')
        apiauth(vip=target['ip'], username=target['username'], password=target_password, mfaCode=target_mfa)

        if apiconnected() is False:
            logger.info('authentication failed for Cluster %s'+ target['ip'])

        cluster_version = get_cluster_version(target['ip'],target)

        if cluster_version is None:
            logger.error("Target Cluster %s is not in supported version"+ target['ip'])
            logger.error("Skipping bootstrapping on Cluster IP "+ target['ip'])


        data = {"privateKey":privateKey, "caChain":cert}
        try:

            # Send an HTTP GET request with the cookies
            response = api('post', 'cert-manager/bootstrap-ca' ,data=data, v=2)
            if response != None:
                time.sleep(120)
                ca_status(target['ip'], cert)
                set_gflag(target['ip'])

            else:
                logger.error(f"Bootstrap request failed!")

        except requests.exceptions.RequestException as e:
            logger.error(f"An error occurred: {e}")


def ca_status(ip, cert):
    """ Function to check Cluster CA status

    Args:
        target (Dict): Target Cluster details
        cert (String): Target Cluster certificate
    """

    try:
        # Send an HTTP GET request with the cookies
        response = api('get', 'cert-manager/ca-status', v=2)
        if response != None:
            target_cert = response.get('caCertChain')
            if target_cert == cert:
                logger.info("Bootstrap is successfull on Cluster "+ ip)
            else:
                logger.error("Bootstrap failed on Cluster "+ ip)
        else:
            logger.error(f"Cohesity CA-status request failed!")

    except requests.exceptions.RequestException as e:
            logger.error(f"An error occurred: {e}")


def set_gflag(ip):
    """Function to update gflag on cluster

    Args:
        target (Dict): Target Cluster details
        session_value (String): Session Value
    """

    gflag = {
        'serviceName': "kMagneto",
        'gflags': [
            {
                'name': "magneto_skip_cert_upgrade_for_multi_cluster_registration",
                'value': "false",
                'reason': "Enable agent certificate update"
            }
        ],
        "effectiveNow": True
    }
    gflag_json = json.dumps(gflag)

    url = 'https://'+ip+'/irisservices/api/v1/clusters/gflag'

    try:
        # Send an HTTP GET request with the cookies
        context = getContext()
        response = requests.put(url, verify=False, headers=context['HEADER'], data=gflag_json)
        response.status_code = 200
        if response == 200:
            logger.info("Successfully updated gflag on Cluster "+ ip)
        else:
            logger.error(f"Updating gflag request failed with status code: {response.status_code}")

    except requests.exceptions.RequestException as e:
            logger.error(f"An error occurred: {e}")


def get_cluster_file(clusterfile):
    """ Function to get cluster details file

    Returns:
        dict: Primary and Target Clusters
    """


    # Get the absolute path of the cluster file
    cluster_file_path = os.path.abspath(clusterfile)
    logger.info("Cluster details found at "+ cluster_file_path)

    try:
        # Open the JSON file for reading
        with open(cluster_file_path, 'r') as json_file:
            # Load the JSON data into a Python dictionary
            cluster_data = json.load(json_file)
            return cluster_data
    except FileNotFoundError:
        logger.error(f"File '{cluster_file_path}' not found.")
        exit(1)
    except json.JSONDecodeError as e:
        logger.error(f"Error decoding JSON: {e}")
        exit(1)


def main():
    """
    Entry point to Certificate improvement
    """

    if clusterfile is None:
        print("Usage: cert.py --cluster <cluster.json>")
        sys.exit(1)

    # fetch cluster details file
    cluster_details = get_cluster_file(clusterfile)

    primary_cl_pw = cluster_details['primary'].get('password')
    primary_mfa = cluster_details['primary'].get('mfaCode')

    logger.info("Authenticating Cluster "+cluster_details['primary']['ip'])
    # authenticate
    apiauth(vip=cluster_details['primary']['ip'], username=cluster_details['primary']['username'], password=primary_cl_pw, mfaCode=primary_mfa)

    # exit if not authenticated
    if apiconnected() is False:
        print('authentication failed for Cluster %s'+ cluster_details['primary']['ip'])
        exit(1)

    # Get Cluster software version
    cluster_version = get_cluster_version(cluster_details['primary']['ip'], cluster_details['primary'])
    if not isinstance(cluster_version, dict):
        return cluster_version

    if cluster_details.get('Targets') == None:
        set_gflag(cluster_details['primary']['ip'])
        return

    # Get Cohesity CA keys
    primary_key, cert = ca_keys()

    bootstrap_targets(cluster_details['targets'], cert, primary_key)

if __name__ == '__main__':
    sys.exit(main())

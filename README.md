# Network Topology Templates

A collection of reusable Azure network topologies defined as Terraform, built for easier and repeatable deployments. Each topology lives in its own folder with a self-contained Terraform configuration and a README describing the architecture, resources, and usage.

## Available architectures

| Architecture | Description |
| --- | --- |
| [Simple Hub-Spoke](./simple-hub-spoke/README.md) | A basic hub-and-spoke design with two spokes connected through VNet peerings and no transitive spoke-to-spoke connectivity. |
| [Hub-Spoke with Azure Firewall and Web Apps](./hub-spokes-webapp-webapp/README.md) | A hub-and-spoke layout that forces cross-spoke traffic through Azure Firewall and exposes a private web app through a Private Endpoint. |
| [Hub-Spoke Web Apps with Custom DNS](./hub-spoke-custom-dns/README.md) | A hub-and-spoke topology that uses a Windows DNS VM in the hub to resolve private App Service endpoints and custom DNS forwarding. |
| [Container Apps with App Gateway](./appgw-aca/README.md) | An internal Azure Container Apps environment behind a public Application Gateway with Easy Auth and custom domain handling. |

## Prerequisites
- Terraform
- Azure CLI logged in via `az login`

See each topology's README for architecture diagrams, inputs, and configuration notes.

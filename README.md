# Flutter Chat App

## 1. Login (Dummy Credentials)

- **Number:** `123`
- **Password:** `123`

## 2. How Dummy Login and JWT Token Work

- The app only accepts login with the number `123` and password `123`.
- Upon successful login, a JWT token with the value `123` is generated and stored locally.
- The app communicates with either a `Strapi` backend or a WebSocket server (`wss://echo.websocket.events`) to echo messages back to the user.
- All chat messages sent and received during the session are stored locally on the device.
- When the user logs out, all stored chat messages are erased.

## 3. Server

The app communicates with a WebSocket server hosted at `wss://echo.websocket.events`. 
This server echoes back any message sent by the user.

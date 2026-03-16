#!/usr/bin/env python3
"""Minimal HTTP MCP client for the local xiaohongshu-mcp server."""

from __future__ import annotations

import json
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Any


class MCPError(RuntimeError):
    """Raised when an MCP call fails."""


@dataclass
class MCPResponse:
    raw: dict[str, Any]
    content_text: str


class MCPHttpClient:
    """Very small JSON-RPC client with session handling."""

    def __init__(
        self,
        base_url: str = "http://localhost:18060/mcp",
        protocol_version: str = "2025-06-18",
        client_name: str = "product-video-xhs-ops",
        client_version: str = "1.0",
    ) -> None:
        self.base_url = base_url
        self.protocol_version = protocol_version
        self.client_name = client_name
        self.client_version = client_version
        self.session_id: str | None = None
        self._request_id = 0

    def initialize(self) -> dict[str, Any]:
        payload = {
            "jsonrpc": "2.0",
            "method": "initialize",
            "params": {
                "protocolVersion": self.protocol_version,
                "capabilities": {},
                "clientInfo": {
                    "name": self.client_name,
                    "version": self.client_version,
                },
            },
            "id": self._next_id(),
        }
        response = self._post(payload, include_session=False, timeout=30)
        if "error" in response:
            raise MCPError(response["error"].get("message", "MCP initialize failed"))
        return response["result"]

    def list_tools(self) -> list[dict[str, Any]]:
        response = self._rpc("tools/list", {}, timeout=30)
        return response.get("result", {}).get("tools", [])

    def call_tool(self, name: str, arguments: dict[str, Any], timeout: int = 300) -> MCPResponse:
        response = self._rpc(
            "tools/call",
            {"name": name, "arguments": arguments},
            timeout=timeout,
        )
        if "error" in response:
            raise MCPError(response["error"].get("message", f"Tool call failed: {name}"))
        result = response.get("result", {})
        content = result.get("content", [])
        text_parts = [
            item.get("text", "")
            for item in content
            if isinstance(item, dict) and item.get("type") == "text"
        ]
        return MCPResponse(raw=response, content_text="\n".join(part for part in text_parts if part).strip())

    def call_tool_json(self, name: str, arguments: dict[str, Any], timeout: int = 300) -> dict[str, Any]:
        response = self.call_tool(name, arguments, timeout=timeout)
        if not response.content_text:
            return {}
        try:
            return json.loads(response.content_text)
        except json.JSONDecodeError as exc:
            raise MCPError(f"Tool {name} returned non-JSON text: {exc}") from exc

    def _rpc(self, method: str, params: dict[str, Any], timeout: int) -> dict[str, Any]:
        if not self.session_id:
            self.initialize()
        payload = {
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": self._next_id(),
        }
        return self._post(payload, include_session=True, timeout=timeout)

    def _post(self, payload: dict[str, Any], include_session: bool, timeout: int) -> dict[str, Any]:
        data = json.dumps(payload).encode("utf-8")
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream",
        }
        if include_session and self.session_id:
            headers["Mcp-Session-Id"] = self.session_id
        request = urllib.request.Request(self.base_url, data=data, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                session_id = response.headers.get("Mcp-Session-Id")
                if session_id:
                    self.session_id = session_id
                body = response.read().decode("utf-8")
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="ignore")
            raise MCPError(f"MCP HTTP {exc.code}: {detail}") from exc
        except urllib.error.URLError as exc:
            raise MCPError(f"Cannot connect to MCP server at {self.base_url}: {exc}") from exc
        return json.loads(body)

    def _next_id(self) -> int:
        self._request_id += 1
        return self._request_id

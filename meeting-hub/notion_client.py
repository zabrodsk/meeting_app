#!/usr/bin/env python3
"""
Notion API spike: create a page from formatted markdown.
Uses integration token (NOTION_API_KEY) and parent page ID.
"""
import os
import httpx

NOTION_VERSION = "2022-02-22"
NOTION_MARKDOWN_VERSION = "2026-03-11"


def create_page_from_markdown(
    parent_page_id: str,
    markdown: str,
    *,
    api_key: str | None = None,
) -> dict:
    """
    Create a Notion page as a child of parent_page_id with markdown content.
    Returns the created page object.
    """
    api_key = api_key or os.environ.get("NOTION_API_KEY")
    if not api_key:
        raise ValueError("NOTION_API_KEY env var or api_key arg required")

    url = "https://api.notion.com/v1/pages"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "Notion-Version": NOTION_MARKDOWN_VERSION,
    }
    payload = {
        "parent": {"page_id": parent_page_id},
        "markdown": markdown,
    }

    with httpx.Client() as client:
        resp = client.post(url, json=payload, headers=headers)
        resp.raise_for_status()
        return resp.json()


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Create Notion page from markdown")
    parser.add_argument(
        "parent_page_id",
        help="Notion page ID to create the new page under (or set NOTION_PARENT_PAGE_ID)",
    )
    parser.add_argument(
        "markdown",
        nargs="?",
        default=None,
        help="Markdown content (or pass via stdin)",
    )
    parser.add_argument(
        "--file", "-f",
        type=argparse.FileType("r"),
        help="Read markdown from file instead",
    )
    args = parser.parse_args()

    parent_id = args.parent_page_id or os.environ.get("NOTION_PARENT_PAGE_ID")
    if not parent_id:
        raise SystemExit("Provide parent_page_id or set NOTION_PARENT_PAGE_ID")

    if args.file:
        markdown = args.file.read()
    elif args.markdown:
        markdown = args.markdown
    else:
        import sys
        markdown = sys.stdin.read()

    if not markdown.strip():
        raise SystemExit("No markdown content provided")

    page = create_page_from_markdown(parent_id, markdown)
    print(f"Created page: {page.get('url', 'N/A')}")
    print(f"Page ID: {page.get('id', 'N/A')}")


if __name__ == "__main__":
    main()

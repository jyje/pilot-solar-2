"""Initialize a deepagents agent at the code level with langchain-upstage
as the model backend, against Upstage's Solar Open2 model.

Unlike Cases 1-2, this never shells out to the `claude` CLI: ChatUpstage
talks to Upstage's OpenAI-compatible endpoint directly, reading
UPSTAGE_API_KEY from the environment.

Three methods, each proving a distinct deepagents capability:
  A. tool use               - a plain custom tool, invoked and answered
  B. virtual filesystem     - deepagents' built-in mock file tools
  C. subagent delegation    - a named subagent handles part of the task
"""

import os
import sys
from typing import Any

from deepagents import SubAgent, create_deep_agent
from langchain_upstage import ChatUpstage

SOLAR_MODEL = os.environ.get("SOLAR_MODEL", "solar-open2")


def solar_model() -> ChatUpstage:
    """Reads UPSTAGE_API_KEY from the environment automatically."""
    return ChatUpstage(model=SOLAR_MODEL)


def truncate(text: str, limit: int = 100) -> str:
    """Collapse whitespace and cap at `limit` chars, matching the
    convention Cases 1-2 use for reporting real evidence."""
    collapsed = " ".join(text.split())
    if len(collapsed) > limit:
        return f"{collapsed[:limit]} ...(truncated)"
    return collapsed


def final_reply(messages: list[Any]) -> str:
    """Pull the last message's text content, empty string if there is none."""
    if not messages:
        return ""
    last = messages[-1]
    content = getattr(last, "content", "")
    return content if isinstance(content, str) else ""


def method_a_tool_use() -> str:
    """A plain custom tool the agent must call to answer correctly."""

    def get_weather(city: str) -> str:
        """Get the weather for a city."""
        return f"It is sunny in {city}."

    agent = create_deep_agent(
        model=solar_model(),
        tools=[get_weather],
        system_prompt="You are a helpful weather assistant.",
    )
    result = agent.invoke(
        {"messages": [{"role": "user", "content": "What is the weather in Seoul?"}]}
    )
    return final_reply(result["messages"])


def method_b_virtual_filesystem() -> str:
    """deepagents' built-in mock filesystem tools (write then read back)."""
    agent = create_deep_agent(
        model=solar_model(),
        system_prompt="You are a helpful assistant with file tools.",
    )
    result = agent.invoke(
        {
            "messages": [
                {
                    "role": "user",
                    "content": (
                        "Write the text HELLO-DEEPAGENTS to a file named "
                        "note.txt using your file tools."
                    ),
                }
            ]
        }
    )
    files = result.get("files", {})
    note = files.get("/note.txt", {})
    return note.get("content", "")


def method_c_subagent_delegation() -> str:
    """A named subagent handles the arithmetic; the main agent reports back."""

    def add_numbers(a: int, b: int) -> int:
        """Add two numbers together."""
        return a + b

    subagents: list[SubAgent] = [
        {
            "name": "math-agent",
            "description": "Use this subagent for any arithmetic/math task.",
            "system_prompt": "You are a math specialist. Use the add_numbers tool.",
            "tools": [add_numbers],
        }
    ]
    agent = create_deep_agent(
        model=solar_model(),
        subagents=subagents,
        system_prompt="Delegate math questions to the math-agent subagent.",
    )
    result = agent.invoke(
        {
            "messages": [
                {
                    "role": "user",
                    "content": (
                        "Use the math-agent subagent to compute 17 + 25, "
                        "then tell me the result."
                    ),
                }
            ]
        }
    )
    return final_reply(result["messages"])


def _main() -> int:
    a_reply = method_a_tool_use()
    print(f"Method A: {truncate(a_reply)}")
    if "sunny" not in a_reply.lower() or "seoul" not in a_reply.lower():
        print(
            f"FAIL: Method A didn't answer the weather question: {a_reply}",
            file=sys.stderr,
        )
        return 1

    b_content = method_b_virtual_filesystem()
    print(f"Method B: {truncate(b_content)}")
    if b_content != "HELLO-DEEPAGENTS":
        print(
            f"FAIL: Method B's file content was wrong: {b_content!r}", file=sys.stderr
        )
        return 1

    c_reply = method_c_subagent_delegation()
    print(f"Method C: {truncate(c_reply)}")
    if "42" not in c_reply:
        print(f"FAIL: Method C's subagent didn't return 42: {c_reply}", file=sys.stderr)
        return 1

    print("All checks passed.")
    return 0


def main() -> None:
    sys.exit(_main())


if __name__ == "__main__":
    main()

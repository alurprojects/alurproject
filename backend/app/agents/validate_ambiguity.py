from app.agents.state import AlurState, DraftTask


def validate_ambiguity_fn(state: AlurState) -> AlurState:
    """Non-LLM Rule Node:

    Validates ambiguity on extracted tasks.
    If estimated_minutes is None, marks is_ambiguous = True.
    """
    drafts = state.get("draft_tasks", [])
    validated_drafts: list[DraftTask] = []

    for draft in drafts:
        is_ambiguous = draft.get("estimated_minutes") is None
        validated_draft = dict(draft)
        validated_draft["is_ambiguous"] = is_ambiguous
        validated_drafts.append(validated_draft)  # type: ignore

    return {"draft_tasks": validated_drafts}

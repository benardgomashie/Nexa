from django.http import JsonResponse


def health_check(_request):
    """Return a simple health status payload for uptime checks."""
    return JsonResponse({"status": "ok"})

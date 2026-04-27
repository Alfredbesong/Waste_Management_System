from rest_framework import permissions, viewsets
from rest_framework.exceptions import PermissionDenied
from rest_framework.generics import CreateAPIView
from rest_framework.response import Response

from .models import WasteReport
from .notification_service import send_report_status_notification
from .serializers import (
    ConfirmationSerializer,
    WasteReportCreateSerializer,
    WasteReportReadSerializer,
    WasteReportStatusSerializer,
)


class WasteReportViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.role == 'admin':
            return WasteReport.objects.select_related('user').order_by('-created_at')
        return WasteReport.objects.filter(user=user).select_related('user').order_by('-created_at')

    def get_serializer_class(self):
        if self.action == 'create':
            return WasteReportCreateSerializer
        if self.action in {'update', 'partial_update'}:
            return WasteReportStatusSerializer
        return WasteReportReadSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        report = serializer.save()
        output_serializer = WasteReportReadSerializer(report, context=self.get_serializer_context())
        headers = self.get_success_headers(output_serializer.data)
        return Response(output_serializer.data, status=201, headers=headers)

    def perform_update(self, serializer):
        if not (self.request.user.is_staff or self.request.user.role == 'admin'):
            raise PermissionDenied('Only admin users can update report status.')

        previous_status = serializer.instance.status
        updated_report = serializer.save()

        if previous_status != updated_report.status:
            send_report_status_notification(updated_report)


class ConfirmationCreateView(CreateAPIView):
    serializer_class = ConfirmationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        report = serializer.validated_data['report']
        if report.user != self.request.user and not self.request.user.is_staff:
            raise PermissionDenied('You can only confirm your own report.')
        serializer.save(user=self.request.user)

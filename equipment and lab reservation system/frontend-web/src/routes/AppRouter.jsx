import { Route, Routes } from 'react-router-dom';
import AdminLayout from '../layouts/AdminLayout.jsx';
import UserLayout from '../layouts/UserLayout.jsx';
import DashboardPage from '../pages/dashboard/DashboardPage.jsx';
import EquipmentListPage from '../pages/equipment/EquipmentListPage.jsx';
import EquipmentDetailsPage from '../pages/equipment/EquipmentDetailsPage.jsx';
import MyBorrowedEquipmentPage from '../pages/equipment/MyBorrowedEquipmentPage.jsx';
import LaboratoryListPage from '../pages/laboratories/LaboratoryListPage.jsx';
import LaboratoryDetailsPage from '../pages/laboratories/LaboratoryDetailsPage.jsx';
import MyReservationsPage from '../pages/reservations/MyReservationsPage.jsx';
import CreateReservationPage from '../pages/reservations/CreateReservationPage.jsx';
import ReservationDetailsPage from '../pages/reservations/ReservationDetailsPage.jsx';
import ReservationApprovalPage from '../pages/admin/ReservationApprovalPage.jsx';
import AdminDashboardPage from '../pages/admin/AdminDashboardPage.jsx';
import UserManagementPage from '../pages/admin/UserManagementPage.jsx';
import EquipmentManagementPage from '../pages/admin/EquipmentManagementPage.jsx';
import EquipmentLoansPage from '../pages/admin/EquipmentLoansPage.jsx';
import LaboratoryManagementPage from '../pages/admin/LaboratoryManagementPage.jsx';
import ScheduleManagementPage from '../pages/admin/ScheduleManagementPage.jsx';
import ReportsPage from '../pages/admin/ReportsPage.jsx';
import AuditTrailPage from '../pages/admin/AuditTrailPage.jsx';
import SettingsPage from '../pages/admin/SettingsPage.jsx';
import ProfilePage from '../pages/profile/ProfilePage.jsx';
import LoginPage from '../pages/auth/LoginPage.jsx';
import RegisterPage from '../pages/auth/RegisterPage.jsx';
import ForgotPasswordPage from '../pages/auth/ForgotPasswordPage.jsx';
import ResetPasswordPage from '../pages/auth/ResetPasswordPage.jsx';
import LandingPage from '../pages/public/LandingPage.jsx';
import NotFoundPage from '../pages/errors/NotFoundPage.jsx';
import UnauthorizedPage from '../pages/errors/UnauthorizedPage.jsx';
import NotificationsPage from '../pages/notifications/NotificationsPage.jsx';
import IssueReportsPage from '../pages/issues/IssueReportsPage.jsx';
import ProtectedRoute from './ProtectedRoute.jsx';

export default function AppRouter() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />
      <Route path="/forgot-password" element={<ForgotPasswordPage />} />
      <Route path="/reset-password" element={<ResetPasswordPage />} />
      <Route path="/landing" element={<LandingPage />} />
      <Route element={<ProtectedRoute><UserLayout /></ProtectedRoute>}>
        <Route index element={<DashboardPage />} />
        <Route path="equipment" element={<EquipmentListPage />} />
        <Route path="equipment/:id" element={<EquipmentDetailsPage />} />
        <Route path="equipment/borrowed" element={<MyBorrowedEquipmentPage />} />
        <Route path="laboratories" element={<LaboratoryListPage />} />
        <Route path="laboratories/:id" element={<LaboratoryDetailsPage />} />
        <Route path="reservations" element={<MyReservationsPage />} />
        <Route path="reservations/new" element={<CreateReservationPage />} />
        <Route path="reservations/:id" element={<ReservationDetailsPage />} />
        <Route path="profile" element={<ProfilePage />} />
        <Route path="notifications" element={<NotificationsPage />} />
        <Route path="issues" element={<IssueReportsPage />} />
        <Route path="unauthorized" element={<UnauthorizedPage />} />
      </Route>
      <Route element={<ProtectedRoute roles={['admin', 'staff']}><AdminLayout /></ProtectedRoute>}>
        <Route path="admin" element={<AdminDashboardPage />} />
        <Route path="admin/reservations" element={<ReservationApprovalPage />} />
        <Route path="admin/users" element={<UserManagementPage />} />
        <Route path="admin/equipment" element={<EquipmentManagementPage />} />
        <Route path="admin/loans" element={<EquipmentLoansPage />} />
        <Route path="admin/laboratories" element={<LaboratoryManagementPage />} />
        <Route path="admin/schedules" element={<ScheduleManagementPage />} />
        <Route path="admin/reports" element={<ReportsPage />} />
        <Route path="admin/audit" element={<AuditTrailPage />} />
        <Route path="admin/settings" element={<SettingsPage />} />
      </Route>
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
}
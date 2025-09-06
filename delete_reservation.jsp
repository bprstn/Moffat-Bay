<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="beans.ReservationBean" %>
<jsp:useBean id="reservationBean" class="beans.ReservationBean" scope="request" />

<%
  // Require login
  Long customerId = (Long) session.getAttribute("customerId");
  if (customerId == null) { response.sendRedirect("signin.jsp"); return; }

  request.setCharacterEncoding("UTF-8");
  String idStr = request.getParameter("id");
  boolean ok = false;

  try {
    if ("POST".equalsIgnoreCase(request.getMethod()) && idStr != null && !idStr.isEmpty()) {
      long reservationId = Long.parseLong(idStr);
      ok = reservationBean.deleteReservation(customerId, reservationId);
    }
  } catch (Exception ignore) {
    ok = false;
  }

  response.sendRedirect("reservations.jsp?msg=" + (ok ? "deleted" : "failed"));
%>

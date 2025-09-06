<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.util.*,java.sql.*" %>
<%@ page import="beans.ReservationBean" %>
<jsp:useBean id="reservationBean" class="beans.ReservationBean" scope="request" />

<%!
  private String h(String s){
    if (s == null) return "";
    return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;");
  }
  private String val(Map<String,Object> row, String... keys){
    for (String k : keys){ Object v = row.get(k); if (v != null) return String.valueOf(v); }
    return "";
  }
  private String currency(Object v){
    if (v == null) return "";
    try{
      double d = (v instanceof Number) ? ((Number)v).doubleValue() : Double.parseDouble(String.valueOf(v));
      return String.format(java.util.Locale.US, "$%.2f", d);
    }catch(Exception e){ return String.valueOf(v); }
  }
  private String statusClass(String s){
    if (s == null) return "status";
    String u = s.toUpperCase(java.util.Locale.US);
    if (u.contains("CONF")) return "status status--ok";
    if (u.contains("PEND")) return "status status--warn";
    if (u.contains("CANCEL")) return "status status--bad";
    return "status";
  }
%>

<%
  // Require login
  Long customerId = (Long) session.getAttribute("customerId");
  String customerEmail = (String) session.getAttribute("customerEmail");
  if (customerId == null) { response.sendRedirect("signin.jsp"); return; }

  List<Map<String,Object>> reservations = new ArrayList<>();
  String errorMsg = null, devError = null;
  boolean treatAsEmpty = false;

  try {
    reservations = reservationBean.findByCustomerId(customerId);
  } catch (Exception ex) {
    if (ex instanceof SQLException) {
      SQLException sx = (SQLException) ex;
      String state = sx.getSQLState();
      if ("42S22".equals(state) || "42S02".equals(state)) { // unknown column/table
        treatAsEmpty = true;
      } else {
        errorMsg = "Could not load your reservations. Please try again.";
        devError = sx.getClass().getName() + " [SQLState=" + sx.getSQLState() + ", Code=" + sx.getErrorCode() + "]: " + sx.getMessage();
      }
    } else {
      errorMsg = "Could not load your reservations. Please try again.";
      devError = ex.getClass().getName() + ": " + ex.getMessage();
    }
  }

  String flash = request.getParameter("msg"); // "deleted" | "failed"
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>My Reservations • Moffat Bay Lodge</title>
  <link href="https://fonts.googleapis.com/css2?family=Lato:wght@300;400;700&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="style.css">
  <style>
    .table-wrap{overflow-x:auto}
    .table{width:100%; border-collapse:separate; border-spacing:0}
    .table th, .table td{padding:12px 14px; vertical-align:middle; white-space:nowrap}
    .table thead th{background:#f2ece2; color:#1E3D34; font-weight:700; text-align:left; border-bottom:1px solid #e2d8c7}
    .table tbody tr{background:#fff}
    .table tbody tr + tr td{border-top:1px solid #eee}
    .table td.room{white-space:normal}
    .muted-sm{opacity:.85; font-size:.92rem}
    .nowrap{white-space:nowrap}
    .status{display:inline-block; padding:.2rem .55rem; border-radius:999px; font-weight:700; font-size:.85rem; border:1px solid transparent}
    .status--ok{background:#e7f5ec; color:#0b6b3a; border-color:#c7e8d2}
    .status--warn{background:#fff5e8; color:#a25a00; border-color:#f2d3a7}
    .status--bad{background:#fde9ea; color:#9b1c1c; border-color:#f3c4c6}
    .btn-danger{border:1px solid #b00020; color:#b00020; background:transparent; padding:.45rem .8rem; border-radius:999px; font-weight:700}
    .btn-danger:hover{opacity:.85}
  </style>
</head>
<body>

<header role="banner">
  <div class="container nav" aria-label="Primary">
    <a class="brand" href="index.html">
      <img src="images/bear_logo.png" alt="Moffat Bay bear logo">
      <span>Moffat Bay Lodge</span>
    </a>
    <nav>
      <ul>
        <li><a href="index.html#about">About</a></li>
        <li><a href="index.html#accommodations">Accommodations</a></li>
        <li><a href="index.html#dining">Dining</a></li>
        <li><a href="index.html#activities">Activities</a></li>
        <li><a href="index.html#contact">Contact</a></li>
        <li><a class="btn btn-ghost auth" href="book.jsp">Book</a></li>
        <li><span class="tag">Signed in: <%= h(customerEmail) %></span></li>
        <li><a class="btn btn-ghost auth" href="signout.jsp">Sign Out</a></li>
      </ul>
    </nav>
  </div>
</header>

<section style="padding:40px 0">
  <div class="container" style="max-width:1100px">
    <h2>My Reservations</h2>
    <p class="muted">Your upcoming and past stays.</p>

    <% if ("deleted".equals(flash)) { %>
      <div class="card" style="border-left:4px solid #1e7f34; margin:16px 0"><div class="pad"><strong>Success:</strong> Reservation deleted.</div></div>
    <% } else if ("failed".equals(flash)) { %>
      <div class="card" style="border-left:4px solid #b00020; margin:16px 0"><div class="pad"><strong>Error:</strong> We couldn't delete that reservation.</div></div>
    <% } %>

    <% if (errorMsg != null) { %>
      <div class="card" style="border-left:4px solid #b00020; margin:16px 0">
        <div class="pad">
          <strong>Error:</strong> <%= h(errorMsg) %>
          <% if (devError != null) { %><pre class="muted" style="white-space:pre-wrap;margin-top:8px"><%= h(devError) %></pre><% } %>
        </div>
      </div>
    <% } else if (treatAsEmpty || reservations.isEmpty()) { %>
      <div class="card" style="margin-top:16px"><div class="pad">You have no reservations yet. <a class="btn btn-primary" style="margin-left:10px" href="book.jsp">Book a room</a></div></div>
    <% } else { %>

      <div class="card" style="margin-top:16px">
        <div class="pad table-wrap">
          <table class="table reservations-table">
            <thead>
              <tr>
                <th>Room</th>
                <th>Check-in</th>
                <th>Check-out</th>
                <th>Guests</th>
                <th>Status</th>
                <th>Rate</th>
                <th>Total</th>
                <th>Booked</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <% for (Map<String,Object> r : reservations) {
                   String room = val(r, "room_name","name");
                   String code = val(r, "room_code","code");
                   String checkIn = val(r, "check_in");
                   String checkOut = val(r, "check_out");
                   String guests = val(r, "guests");
                   String status = val(r, "status");
                   String rate = currency(r.get("rate_at_booking"));
                   String total = currency(r.get("total_price"));
                   String created = val(r, "created_at","created");
                   String idStr = String.valueOf(r.get("id"));
              %>
                <tr>
                  <td class="room">
                    <strong><%= h(room.isEmpty() ? "Room Type " + h(val(r,"room_type_id")) : room) %></strong>
                    <% if (!code.isEmpty()) { %><div class="muted-sm">(<%= h(code) %>)</div><% } %>
                  </td>
                  <td class="nowrap"><%= h(checkIn) %></td>
                  <td class="nowrap"><%= h(checkOut) %></td>
                  <td class="nowrap"><%= h(guests) %></td>
                  <td><span class="<%= statusClass(status) %>"><%= h(status) %></span></td>
                  <td class="nowrap"><%= h(rate) %></td>
                  <td class="nowrap"><%= h(total) %></td>
                  <td class="nowrap"><%= h(created) %></td>
                  <td>
                    <form method="post" action="delete_reservation.jsp"
                          onsubmit="return confirm('Delete this reservation? This cannot be undone.');"
                          style="display:inline">
                      <input type="hidden" name="id" value="<%= h(idStr) %>">
                      <button type="submit" class="btn-danger">Delete</button>
                    </form>
                  </td>
                </tr>
              <% } %>
            </tbody>
          </table>
        </div>
      </div>

    <% } %>
  </div>
</section>

<footer id="contact">
  <div class="container">
    <div class="grid">
      <div class="col-6">
        <h3 style="color:#f0e7d9">Contact</h3>
        <p>4070 Old Moffat Bay Rd, Hilton Beach, ON P0R 1G0, Canada</p>
        <p><a href="mailto:stay@moffatbay.com" style="color:var(--amber-glow)">stay@moffatbay.com</a> • (555) 555-0123</p>
      </div>
      <div class="col-6" style="display:flex; align-items:center; justify-content:flex-end; gap:10px">
        <a class="btn btn-ghost" href="book.jsp">Book</a>
        <a class="btn btn-ghost" href="signout.jsp" aria-label="Sign out">Sign Out</a>
      </div>
    </div>
  </div>
</footer>

</body>
</html>

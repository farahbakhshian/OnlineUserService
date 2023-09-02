<%@ WebService Language="C#" Class="OnlineUserService" %>

using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Net;
using System.Web;
using System.Web.Services;

[WebService]
public class OnlineUserService : WebService
{
    private ConcurrentDictionary<string, OnlineUser> OnlineUsers_Hash
    {
        get
        {
            if (Application["OnlineUsers_Hash"] != null)
                return (ConcurrentDictionary<string, OnlineUser>)Application["OnlineUsers_Hash"];
            else
            {
                Application.Add("OnlineUsers_Hash", new ConcurrentDictionary<string, OnlineUser>());
                return (ConcurrentDictionary<string, OnlineUser>)Application["OnlineUsers_Hash"];
            }
        }
        set
        {
            if (Application["OnlineUsers_Hash"] != null)
                Application["OnlineUsers_Hash"] = value;
            else
                Application.Add("OnlineUsers_Hash", value);
        }
    }

    private List<OnlineUser> OnlineUsers_List
    {
        get
        {
            if (Application["OnlineUsers_List"] != null)
                return ((List<OnlineUser>)Application["OnlineUsers_List"]);
            else
            {
                Application.Add("OnlineUsers_List", new List<OnlineUser>());
                return ((List<OnlineUser>)Application["OnlineUsers_List"]);
            }

        }
        set
        {
            if (Application["OnlineUsers_List"] != null)
                Application["OnlineUsers_List"] = value;
            else
                Application.Add("OnlineUsers_List", value);

        }
    }

    [WebMethod]
    public List<OnlineUser> GetOnlineUsers()
    {
        return OnlineUsers_List;
    }

    [WebMethod]
    public int NumberofOnlineUsers()
    {
        try
		{
			var count = OnlineUsers_List.Count();
			return count;
		}
		catch
		{
			return 0;
		}
    }

    [WebMethod]
    public void AddUser(int UserID, string SessionID)
    {
		try
		{
			Application.Lock();
			
			DateTime CurrentDate = DateTime.Now;
			OnlineUser User = null;
			bool isItemExists1 = OnlineUsers_Hash.TryGetValue(SessionID, out User);
			if (User == null)
			{
				User = new OnlineUser();
				User.UserID = UserID;
				User.LastActivity = DateTime.Now;
				User.SessionID = SessionID;
				User.Status = "Active";

				OnlineUsers_Hash.TryAdd(SessionID, User);
				OnlineUsers_List.Add(User);
			}
			else
			{
				User.Status = "Active";
				User.LastActivity = DateTime.Now;
				User.UserID = UserID;
				bool returnTrue = OnlineUsers_Hash.TryUpdate(SessionID, User, User);
			}
		}
		catch (Exception ex) { }
		finally
		{
			Application.UnLock();
		}
    }

    private void UpdateAllUsers()
    {
		List<string> lstRemoved = new List<string>();
		foreach (var u in OnlineUsers_List)
		{
			var differD = DateTime.Now.Subtract(u.LastActivity).Days;
			var differH = DateTime.Now.Subtract(u.LastActivity).Hours;
			var differM = DateTime.Now.Subtract(u.LastActivity).Minutes;
			var differ = (differD * 24 * 60) + (differH * 60) + differM; 

			if (differ > Convert.ToInt32(ConfigUtility.AppSettings("RemoveSessionTime")) ||
				(u.UserID == 0 && differ > 30))//30
			{
				lstRemoved.Add(u.SessionID);
			}
			else if (differ > 15))// disable user without activity after 15 minutes
				u.Status = "Inactive";
		}

		foreach (var item in lstRemoved)
		{
			OnlineUser u = null;
			bool isItemExists1 = OnlineUsers_Hash.TryGetValue(item, out u);
			OnlineUsers_List.Remove(u);
			OnlineUsers_Hash.TryRemove(item, out u);
		}
    }

    [WebMethod]
    public void RemoveUser(string SessionID)
    {
        OnlineUser user = null;
        bool isItemExists1 = OnlineUsers_Hash.TryGetValue(SessionID, out user);
        if (isItemExists1)
        {
            user.Status = "Removed";
            OnlineUsers_Hash.TryUpdate(SessionID, user, user);
        }
    }

    [WebMethod]
    public void SignOut(string SessionID)
    {
        try
		{
			Application.Lock();

			OnlineUser u = null;
			bool isItemExists1 = OnlineUsers_Hash.TryGetValue(SessionID, out u);
			
			OnlineUsers_List.Remove(u);
			OnlineUsers_Hash.TryRemove(SessionID, out u);
		}
		catch (Exception ex) { }
		finally
		{
			Application.UnLock();
		}
    }
}


[global::System.Runtime.Serialization.DataContractAttribute()]
public class OnlineUser
{
    [global::System.Runtime.Serialization.DataMemberAttribute(Order = 2)]
    public int UserID;

    [global::System.Runtime.Serialization.DataMemberAttribute(Order = 3)]
    public DateTime LastActivity;

    [global::System.Runtime.Serialization.DataMemberAttribute(Order = 9)]
    public string SessionID;

    [global::System.Runtime.Serialization.DataMemberAttribute(Order = 10)]
    public string Status;
}

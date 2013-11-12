/**
 *	Copyright (c) 2013 by Christian Johnson (_c_@mail.com)
 *	
 *	This file is part of WhiteHouse, the Interactive Fiction Mapper.
 *	
 *	WhiteHouse is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *	
 *	WhiteHouse is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *	
 *	You should have received a copy of the GNU General Public License
 *	along with WhiteHouse.  If not, see <http://www.gnu.org/licenses/>.
 */

package com.github.redhatter.whitehouse;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Dialog;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.layout.FormLayout;
import org.eclipse.swt.layout.FormData;
import org.eclipse.swt.layout.FormAttachment;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;

public class RoomDialog extends Dialog
{
    public RoomDialog(Shell parent, final Room room)
    {
        super(parent, SWT.DIALOG_TRIM|SWT.APPLICATION_MODAL|SWT.RESIZE);
		
		// Create window, set layout
		final Shell shell = new Shell(parent, SWT.DIALOG_TRIM|SWT.APPLICATION_MODAL|SWT.RESIZE);
		shell.setText("Room Properties");
		FormLayout layout = new FormLayout();
		layout.marginWidth = 15;
		layout.marginHeight = 15;
		layout.spacing = 15;
		shell.setLayout(layout);
		
		// Name label attached to top of window
		Label label = new Label(shell, SWT.NONE);
		label.setText("Name ");
		FormData data = new FormData();
		data.top = new FormAttachment(0);
		label.setLayoutData(data);
		
		// Name input attached to label and both sides of window, so as to grow
		final Text name = new Text(shell, SWT.BORDER);
		name.setText(room.getName());
		data = new FormData();
		data.top = new FormAttachment(label);
		data.right = new FormAttachment(100);
		data.left = new FormAttachment(0);
		name.setLayoutData(data);
		
		// Cancel button attached to bottom right of window. Simply closes dialog.
		Button cancel = new Button(shell, SWT.PUSH);
		cancel.setText("Cancel");
		cancel.addSelectionListener(new SelectionAdapter ()
		{
			public void widgetSelected(SelectionEvent e)
			{
				shell.dispose();
			}
		});
		data = new FormData();
		data.width = 70;
		data.bottom = new FormAttachment(100);
		data.right = new FormAttachment(100);
		cancel.setLayoutData(data);
		
		// OK buttom attached to bottom of window and cancel button
		Button ok = new Button(shell, SWT.PUSH);
		ok.setText("OK");
		data = new FormData();
		data.width = 70;
		data.bottom = new FormAttachment(100);
		data.right = new FormAttachment(cancel);
		ok.setLayoutData(data);
		
		// Description label attached to name input
		label = new Label(shell, SWT.NONE);
		label.setText("Description ");
		data = new FormData();
		data.top = new FormAttachment(name);
		label.setLayoutData(data);
		
		// Description input attached to both sides of window, cancel button, and
		// description label
		final Text description = new Text(shell, SWT.BORDER|SWT.WRAP|SWT.MULTI);
		description.setText(room.getDesc());
		data = new FormData();
		data.right = new FormAttachment(100);
		data.left = new FormAttachment(0);
		data.bottom = new FormAttachment(cancel);
		data.top = new FormAttachment(label);
		description.setLayoutData(data);
		
		// OK button sets the room description and name then closes the window
		ok.addSelectionListener(new SelectionAdapter ()
		{
			public void widgetSelected(SelectionEvent e)
			{
				room.setName(name.getText());
				room.setDesc(description.getText());
				shell.dispose();
			}
		});
		
		shell.setSize(500, 300);
		shell.open();
		
		// Each shell has its' own event loop
		Display display = parent.getDisplay();
		while (!shell.isDisposed())
			if (!display.readAndDispatch())
				display.sleep();
    }
}
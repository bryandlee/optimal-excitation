function robot = makeAtlasV5()
    robot = parseAtlasXML();

    root = 13; % lfoot

    robot_foot = robot;
    robot_foot.root = root;

    link = root;
    robot_foot.tree{root}.parent = link;
    robot_foot.tree{root}.children = robot.tree{root}.parent;

    while (1)
        new_child = robot.tree{link}.parent;

        robot_foot.M(:,:,new_child) = inverse_SE3(robot.M(:,:,link));
        robot_foot.A(:,new_child) = large_Ad(robot_foot.M(:,:,new_child)) * (-robot.A(:,link));
        robot_foot.q_min(new_child) = robot.q_min(link);
        robot_foot.q_max(new_child) = robot.q_max(link);

        if new_child ~= robot.root
            robot_foot.tree{new_child}.children = robot.tree{new_child}.parent;
            robot_foot.tree{new_child}.parent = link;
            link = new_child;
        else
            break;
        end
    end

    robot_foot.tree{robot.root}.children = [14,2]';
    robot_foot.tree{robot.root}.parent = 8;

    robot_foot.A(:,robot_foot.root) = zeros(6,1);

    robot = robot_foot;
    
    % B

    % Phi
    robot.Phi = zeros(10*robot.dof,1);
    for i = 1:robot.dof
        robot.Phi(10*(i-1)+1:10*i) = convertInertiaGToPhi(robot.G(:,:,i));
    end
    
    robot.pd_metric_Phi = zeros(10*robot.dof, 10*robot.dof);
    for i = 1:robot.dof
        robot.pd_metric_Phi(10*(i-1)+1:10*i, 10*(i-1)+1:10*i) = getPDMetricInertiaPhi(robot.Phi(10*(i-1)+1:10*i));
    end
    
    % temporary..
    robot.B_metric_inv_Phi_Bt = robot.B * pinv(robot.pd_metric_Phi) * robot.B';
    robot.B_metric_inv_Phi_Bt = (robot.B_metric_inv_Phi_Bt+robot.B_metric_inv_Phi_Bt')/2;
    
    robot.qdot_min = -10*ones(robot.dof,1);
    robot.qdot_max = 10*ones(robot.dof,1);
    
    robot.zmp_x_min = -0.08;
    robot.zmp_x_max = 0.15;
    robot.zmp_y_min = -0.05;
    robot.zmp_y_max = 0.05;
end
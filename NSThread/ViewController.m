//
//  ViewController.m
//  NSThread
//
//  Created by DB_MAC on 2017/6/5.
//  Copyright © 2017年 db. All rights reserved.
//

// 多线程技术（并发编程）： Pthread NSThread    并发技术（已封装了多线程）:GCD NSOperation(多用)
// 线程安全：在多个线程进行读写操作时 ，仍然保证数据的正确
// UI线程 共同约定：所有更新UI 的操作都放着主线程上执行（保证了线程安全） 这个设计的原因：UIKit框架都是线程不安全的（线程安全效率低）

//下载图片（在网络上传输的所有数据都是二进制）
//为什么是二进制：因为物理层是网线  网线里面是电流 电流有高低电频  高低电频表示二进制

#import "ViewController.h"


@interface ViewController ()

@property (nonatomic, assign) int tickets;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.tickets = 20;
    
    NSData *data;
    //原子属性 == yes 先把文件保存在一个临时的文件中  等全部写入之后 再改名
    
    //原子属性 atomic  保证这个属性的安全性（线程安全 针对多线程设计的） 目的：多个线程访问同一个对象的时候保证写入对象的时候同一时间只有一个线程能够执行  实际上写入对象的时候原子属性内部有一个 自旋锁（为setter方法加锁）
    //如果一个对象 有可能被多线程访问  那么就需要将对象设置成 原子属性atomic
    
    //自旋锁 互斥锁 共同点：都能保证线程安全  不同点：互斥锁：如果线程被锁在外面，线程就会进入休眠状态 锁打开后被唤醒  自旋锁：如果线程被锁在外面，线程就会用死循环的方式，一直等待锁打开  无论什么锁都消耗性能，效率都不高
    
    //原子属性 单写多读的一种多线程技术  数据成为判断的依据的时候 同样有可能出现”脏数据“，需要重新读一下
    [data writeToFile:@"文件路径" atomically:YES];
    
    
    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [self threadDemo1];
    
}

////////////////////////////多线程  --->

-(void)threadDemo1{
    
    //线程的状态
    //线程对象  NEW（新建） > Runnable(就绪) > Running(CPU来回切换 运行) 放于可调度线程池进入线程池就进入了就绪状态   CPU来回切换调度线程即进入运行状态     调用sleep或者线程锁则线程处于阻塞状态（Blocked  此时不在可调度池）    线程结束/异常/强制退出 -> 死亡状态（Dead）
    
    
    //创建线程
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(demo:) object:@"Thread"];
    thread.name = @"这是哥的线程";//在大型项目中   通常希望在奔溃的时候能够获取到准确的所在线程
    //线程就绪
    [thread start];//启动线程
    
    
}

-(void)threadDemo2{
    //detach -->分离  分离一个子线程  只要一分离马上就执行
    NSLog(@"A--->%@",[NSThread currentThread]);//在主线程 1
    
    [NSThread detachNewThreadSelector:@selector(demo:) toTarget:self withObject:@"Thread"];
    
    
    NSLog(@"B--->%@",[NSThread currentThread]);//在主线程 1

}

-(void)threadDemo3{
    //    InBackground 即在后台线程 在子线程执行
    //    是NSObject的分类  意味着所有的基础NSObject的都可以使用这个方法  非常方便不用NSThread对象
    
    [self performSelectorInBackground:@selector(demo:) withObject:@"ThreadBackground"];
    
    //线程间的通讯  面试经常会问  有五个方法
    //
//    [self performSelectorInBackground:@selector(demo:) withObject:@""];
//    [self performSelectorOnMainThread:@selector(demo:) withObject:@"" waitUntilDone:NO];
//    performSelector...
    
    
}

-(void)demo:(id)obj{
    
    //在非主线程 非1  多线程目的：耗时操作放于子线程处理防止阻塞主线程影响用户体验
    
    
    //阻塞线程 sleep  当满足某个条件的时候 让线程休眠一会儿
    [NSThread sleepForTimeInterval:2];
    
    for (int i = 0; i<8; i++) {
        NSLog(@"%@---%@",obj,[NSThread currentThread]);
        
        if(i == 5){
            //就当满足某个条件的时候  可以强制终止线程  终止后后续代码将停止运行
            //注意：在终止线程 应该要释放之前分配的对象
            [NSThread exit];//会杀掉主线程 但是app不会挂掉
        }
    }
}

////////////////////////////多线程  <---


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

////////////////////////////互斥锁  -->

-(void)saleTickets{
    while (YES) {
        [NSThread sleepForTimeInterval:2];
        //互斥锁  保证锁内的代码 同一时间 只有一条线程执行
        //互斥锁的范围应该尽量小  范围大了效率差
        //参数：任意oc对象都ok 需要共有的对象  一般用self全局对象
        @synchronized (self) {
            if (self.tickets > 0) {
                self.tickets--;
                NSLog(@"%@",[NSThread currentThread]);
            }else{
                //票卖完了
                NSLog(@"%@",[NSThread currentThread]);
                break;
                
            }
        }
    }
}
-(void)threadSaleTickets{
    
    NSThread *t1 = [[NSThread alloc] initWithTarget:self selector:@selector(saleTickets) object:nil];
    t1.name = @"售票员 A";
    [t1 start];
    
    NSThread *t2 = [[NSThread alloc] initWithTarget:self selector:@selector(saleTickets) object:nil];
    t2.name = @"售票员 B";
    [t2 start];
    
//    两个线程同时操作变量  需要加互斥锁  否则会出错

    
}
////////////////////////////互斥锁  <----

@end

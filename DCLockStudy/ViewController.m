//
//  ViewController.m
//  DCLockStudy
//
//  Created by 戴川 on 2019/4/22.
//  Copyright © 2019 DC. All rights reserved.
//

#import "ViewController.h"
#import <pthread.h>

@interface ViewController ()
@property (nonatomic, strong) NSMutableArray *mutableArray;
/** 常规锁 */
@property (nonatomic, strong) NSLock *myLock;
/** 递归锁 */
@property (nonatomic, strong) NSRecursiveLock *recursiveLock;
/** 条件锁 */
@property (nonatomic, strong) NSConditionLock *conditionLock;
/** 条件变量 */
@property (nonatomic, strong) NSCondition *condition;
@end

static pthread_mutex_t pMutex;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self __initialize];
    
    
    
//    for(NSInteger i=0; i<10; i++){
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
////            [self __synchronizedLockWithNum:i];
//
//            [self __NSLockWithNum:i];
//        });
//    }
    
//    [self __tryLockAndDate];
    
//    [self __NSRecursiveLock];
    
//    [self __NSConditionLock];
    
//    [self __NSCondition];
    
//    [self __dispatch_semaphore];
    
//    [self __pthread_mutex_t];
    
//    [self threadSafe];
    
}
- (void)threadNotSafe {
   __block NSInteger total = 0;
    for (NSInteger index = 0; index < 3; index++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            total += 1;
            NSLog(@"total: %ld", total);
            total -= 1;
            NSLog(@"total: %ld", total);
        });
    }
}
- (void)threadSafe {
    __block NSInteger total = 0;
    NSLock *myLock = [[NSLock alloc]init];
    for (NSInteger index = 0; index < 3; index++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [myLock lock];
            total += 1;
            NSLog(@"total: %ld", total);
            total -= 1;
            NSLog(@"total: %ld", total);
            [myLock unlock];
        });
    }
}

#pragma mark - private
- (void)__initialize{
    //初始化数组
    NSMutableArray *mutableArray = [[NSMutableArray alloc]initWithCapacity:10];
    for(NSInteger i = 0; i<10; i++){
        [mutableArray addObject:[NSString stringWithFormat:@"%ld",i]];
    }
    self.mutableArray = mutableArray;
    
    //普通锁
    NSLock *myLock = [[NSLock alloc]init];
    self.myLock = myLock;
    
    //递归锁
    NSRecursiveLock *recursiveLock = [[NSRecursiveLock alloc]init];
    self.recursiveLock = recursiveLock;
    
    //条件锁
    NSConditionLock *conditionLock = [[NSConditionLock alloc]init];
    self.conditionLock = conditionLock;
    
    NSCondition *condition = [[NSCondition alloc]init];
    self.condition = condition;
    
    //创建一个互斥锁
    pthread_mutex_init(&pMutex,PTHREAD_MUTEX_NORMAL);

}

- (void)__synchronizedLockWithNum:(NSInteger)num{
    /** 该方法比较常见，和NSLock功能相同,参数一般传入self，只能给一个对象加锁;
        但性能最低，不推荐使用;
        死锁：synchronize所不能嵌套使用，会造成死锁；
     */
  
    //多线程同时修改mutableArray[0]
    @synchronized (self.mutableArray) {
        NSLog(@"replace = %ld, start",num);
        [self.mutableArray replaceObjectAtIndex:0 withObject:[NSString stringWithFormat:@"replace = %ld",num]];
        NSLog(@"mutableArray[0] = %@",self.mutableArray[0]);
        sleep(2);
        NSLog(@"replace = %ld, end",num);
    }
   
}

- (void)__NSLockWithNum:(NSInteger)num{
    /** NSLock实现了最基本的互斥锁，遵循NSLocking协议，通过lock和unLock来进行锁定于解锁。
     当一个线程访问的时候，该线程获得锁，其他线程访问的时候，将被操作系统挂起，直到该线程释放锁，其他线程才能对其进行访问，从而确保线程安全
     注意，这里的lock必须用同一个锁，所以不能临时创建一个lock来进行加锁，必须创建全局的；
     死锁：同一个线程，不能同时加两把锁；在递归锁中会详细介绍；
     */

    [self.myLock lock];
    
    NSLog(@"replace = %ld, start",num);
    [self.mutableArray replaceObjectAtIndex:0 withObject:[NSString stringWithFormat:@"replace = %ld",num]];
    NSLog(@"mutableArray[0] = %@",self.mutableArray[0]);
    sleep(2);
    NSLog(@"replace = %ld, end",num);
    
    [self.myLock unlock];
    
}

- (void)__tryLockAndDate{
    /** tryLock 尝试获取锁，如果这个时候，别的线程添加了锁，则返回NO，不会阻塞线程；
        lockBeforeDate，尝试在某个时间之前获取锁，如果在这个时间内没有获取到锁则返回NO，不会阻塞线程；
     */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //lockBeforeDate会在指定的时间之前加锁，所以已经使用过[_lock lock]了.下面相当于在当前时间之前上锁了。
        [self.myLock lockBeforeDate:[NSDate date]];
        NSLog(@"线程1需要线程同步的操作1 开始");
        sleep(2);
        NSLog(@"线程1需要线程同步的操作1 结束");
        [self.myLock unlock];
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        NSLog(@"线程2尝试获取锁");
        if ([self.myLock tryLock]) {//尝试获取锁，如果获取不到返回NO，不会阻塞该线程
            NSLog(@"线程2获取锁成功");
            [self.myLock unlock];
        }else{
            NSLog(@"线程2获取锁失败，恢复线程");
        }
        
        NSDate *date = [[NSDate alloc] initWithTimeIntervalSinceNow:3];
        NSLog(@"线程2尝试在3秒内获取锁");
        if ([self.myLock lockBeforeDate:date]) {
            //尝试在未来的3s内获取锁，并阻塞该线程，如果3s内获取不到恢复线程, 返回NO,不会阻塞该线程
            NSLog(@"线程2在3秒内获得锁");
            [self.myLock unlock];
        }else{
            NSLog(@"线程2在3秒内没有获得锁，恢复线程");
        }
    });
}

- (void)__NSRecursiveLock{
    /** NSRecursiveLock递归锁
        它可以被同一线程多次请求，但不会引起死锁。这主要是用在循环或者递归操作场景中。
     */
    /** 如果用普通锁，当第二次进入递归方法时，尝试加锁，但是这个时候该线程还处于锁定，所以线程阻塞，相互等待造成死锁。
     所以这个时候可以用一个递归锁，允许同一线程多次请求，并且不会死锁；
     NSRecursiveLock 递归锁和NSLock一样也有tryLock和lockBeforeDate，用法一样；
     */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static void (^ recursiveMethod)(NSInteger);
        recursiveMethod = ^(NSInteger num){
            //    [self.myLock lock];
            [self.recursiveLock lock];
            if(num > 0){
                num --;
                NSLog(@"start num = %ld, mutableArray[0] = %@",num,self.mutableArray[0]);
                sleep(1);
                [self.mutableArray replaceObjectAtIndex:0 withObject:[NSString stringWithFormat:@"replace = %ld",num]];
                NSLog(@"end num = %ld, mutableArray[0] = %@",num,self.mutableArray[0]);
                recursiveMethod(num);
            }
            //    [self.myLock unlock];
            [self.recursiveLock unlock];
        };
        recursiveMethod(5);

    });
}

- (void)__NSConditionLock{
    /**条件锁  NSConditionLock
        因为遵守了NSLocking协议，所以可以无条件加锁lock，
     */
    dispatch_queue_t conditionLockQueue = dispatch_queue_create("conditionLockQueue", DISPATCH_QUEUE_CONCURRENT);
    //线程1
    dispatch_async(conditionLockQueue, ^{
        NSLog(@"进入线程1，添加条件锁 = 2，如果condition != 2,则线程阻塞");
        [self.conditionLock lockWhenCondition:2];
        NSLog(@"线程1加锁成功，lockWhenCondition:2");
        [self.conditionLock unlock];
        NSLog(@"线程1解锁锁成功，unlockWithCondition:1");
    });
    
    //线程2
    dispatch_async(conditionLockQueue, ^{
        sleep(1); //保证线程3先执行
        NSLog(@"进入线程2，尝试添加条件锁 = 1");
        if([self.conditionLock tryLockWhenCondition:1]){
            NSLog(@"线程2加锁成功，lockWhenCondition:1");
            [self.conditionLock unlockWithCondition:2];
            NSLog(@"线程2解锁成功，unlockWithCondition:1");
        }else{
            NSLog(@"线程2加锁失败");
        }
    });
    
    //线程3
    dispatch_async(conditionLockQueue, ^{
//        sleep(1); //保证线程2先执行
        NSLog(@"进入线程3，尝试添加条件锁 = 0");
        if([self.conditionLock tryLockWhenCondition:0]){
            NSLog(@"线程3加锁成功，lockWhenCondition:0");
            [self.conditionLock unlockWithCondition:1];
            NSLog(@"线程3解锁成功，unlockWithCondition:1");
        }else{
            NSLog(@"线程3加锁失败");
        }
    });
    
    /** 先进入线程1，条件不满足，线程1阻塞，
        进入线程3，线程3满足条件，线程3加锁，线程3解锁并将条件设置为1；
        进入线程2，线程满足条件，线程2加锁，线程2解锁，并将条件设置为2；
        因为条件为2，线程1满足条件了，线程1不在阻塞，线程1加锁，线程1解锁；
     */
}

- (void)__NSCondition{
    /** 条件变量
     wait：进入等待状态
     waitUntilDate:：让一个线程等待一定的时间
     signal：唤醒一个等待的线程
     broadcast：唤醒所有等待的线程
     */
    //线程1
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.condition lock];
        NSLog(@"线程1获取到锁，并进入等待状态");
        [self.condition wait];
        NSLog(@"线程1等待完成");
        [self.condition unlock];
        NSLog(@"线程1解锁");
    });
    
    //线程2
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.condition lock];
        NSLog(@"线程2获取到锁，并进入等待状态");
        [self.condition wait];
        NSLog(@"线程2等待完成");
        [self.condition unlock];
        NSLog(@"线程2解锁");
    });
    
    //线程3
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(1);
        NSLog(@"线程3，唤醒一个等待线程");
        [self.condition signal];
        
        sleep(2);
        NSLog(@"线程3，唤醒所有等待线程");
        [self.condition broadcast];
    });
}

- (void)__dispatch_semaphore{
    /**
        dispatch_semaphore_create(1)： 传入值必须 >=0, 若传入为 0 则阻塞线程并等待timeout,时间到后会执行其后的语句
        dispatch_semaphore_wait(signal, overTime)：可以理解为 lock,会使得 signal 值 -1
        dispatch_semaphore_signal(signal)：可以理解为 unlock,会使得 signal 值 +1
    
        停车场剩余4个车位，那么即使同时来了四辆车也能停的下。如果此时来了五辆车，那么就有一辆需要等待。
        信号量的值（signal）就相当于剩余车位的数目，dispatch_semaphore_wait 函数就相当于来了一辆车，dispatch_semaphore_signal 就相当于走了一辆车。停车位的剩余数目在初始化的时候就已经指明了（dispatch_semaphore_create（long value）），调用一次 dispatch_semaphore_signal，剩余的车位就增加一个；调用一次dispatch_semaphore_wait 剩余车位就减少一个；当剩余车位为 0 时，再来车（即调用 dispatch_semaphore_wait）就只能等待。有可能同时有几辆车等待一个停车位。有些车主没有耐心，给自己设定了一段等待时间，这段时间内等不到停车位就走了，如果等到了就开进去停车。而有些车主就像把车停在这，所以就一直等下去。
    */
    dispatch_semaphore_t signal = dispatch_semaphore_create(1);//传入值必须>=0;如果传入0，
    dispatch_time_t overTime = dispatch_time(DISPATCH_TIME_NOW,2.0f * NSEC_PER_SEC);
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"线程1等待中。。。");
        dispatch_semaphore_wait(signal, overTime);
        NSLog(@"线程1");
        sleep(1);
        dispatch_semaphore_signal(signal);
        NSLog(@"线程1发送信号");
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"线程2等待中。。。");
        dispatch_semaphore_wait(signal, overTime);
        NSLog(@"线程2");
        sleep(1);
        dispatch_semaphore_signal(signal);
        NSLog(@"线程2发送信号");
    });
}

- (void)__pthread_mutex_t{
    /**
     声明 pthread_mutex_t pMutex;
        创建一个互斥锁pthread_mutex_init(&pMutex,PTHREAD_MUTEX_NORMAL);
         PTHREAD_MUTEX_NORMAL 缺省类型，也就是普通锁。当一个线程加锁以后，其余请求锁的线程将形成一个等待队列，并在解锁后先进先出原则获得锁。
         PTHREAD_MUTEX_ERRORCHECK 检错锁，如果同一个线程请求同一个锁，则返回 EDEADLK，否则与普通锁类型动作相同。这样就保证当不允许多次加锁时不会出现嵌套情况下的死锁。
         PTHREAD_MUTEX_RECURSIVE 递归锁，允许同一个线程对同一个锁成功获得多次，并通过多次 unlock 解锁。
         PTHREAD_MUTEX_DEFAULT 适应锁，动作最简单的锁类型，仅等待解锁后重新竞争，没有等待队列。
        加锁 pthread_mutex_lock(&pMutex);
        解锁 pthread_mutex_unlock(&pMutex);
 */
    //线程1
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"线程1加锁");
        pthread_mutex_lock(&pMutex);
        sleep(1);
        NSLog(@"线程1");
        pthread_mutex_unlock(&pMutex);
        NSLog(@"线程1解锁");
    });
    //线程2
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        sleep(1); //保证线程1先加锁
        NSLog(@"线程2加锁");
        pthread_mutex_lock(&pMutex);
        NSLog(@"线程2");
        pthread_mutex_unlock(&pMutex);
        NSLog(@"线程2解锁");
    });
}
@end
